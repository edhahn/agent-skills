# ZenStack v3 Access Control Reference

Access control in ZenStack v3 is defined in the schema and enforced at runtime via SQL query injection. It's database-agnostic (not relying on row-level security).

## Setup

### 1. Install the Policy Plugin

```bash
npm install @zenstackhq/plugin-policy
```

### 2. Enable in Schema

```zmodel
plugin policy {
  provider = '@zenstackhq/plugin-policy'
}
```

### 3. Install at Runtime

```typescript
import { ZenStackClient } from '@zenstackhq/orm';
import { PolicyPlugin } from '@zenstackhq/plugin-policy';

// Raw client (no access control)
const db = new ZenStackClient(schema, { dialect: ... });

// Client with access control
const authDb = db.$use(new PolicyPlugin());

// User-bound client
const userDb = authDb.$setAuth(currentUser);
```

> `$use()` and `$setAuth()` return NEW immutable client instances (cheap shallow clones, no new DB connections).

## Writing Policies

### Rule Types

- `@@allow(operation, condition)` — whitelist rule
- `@@deny(operation, condition)` — blacklist rule

### Evaluation Order

1. If any `@@deny` rule is true → **denied**
2. If any `@@allow` rule is true → **allowed**
3. Otherwise → **denied** (secure by default)

Rule order doesn't matter. Write as many as needed.

### Operations

| Operation | Description |
|-----------|-------------|
| `read` | Query/filter records |
| `create` | Create new records |
| `update` | Update existing records |
| `post-update` | Conditions after update (must be explicit) |
| `delete` | Delete existing records |
| `all` | Shorthand for create, read, update, delete (NOT post-update) |

Multiple operations: `@@allow('create,read', true)`

### Complete Example

```zmodel
plugin policy {
  provider = '@zenstackhq/plugin-policy'
}

model User {
  id    Int    @id @default(autoincrement())
  email String @unique
  posts Post[]

  @@allow('create,read', true)
  @@allow('all', auth().id == id)
}

model Post {
  id        Int     @id @default(autoincrement())
  title     String
  published Boolean @default(false)
  author    User    @relation(fields: [authorId], references: [id])
  authorId  Int

  @@deny('all', auth() == null)        // no anonymous access
  @@allow('read', published)            // published = public
  @@allow('all', auth().id == authorId) // author has full access
}
```

## Expressions and Functions

### auth() — Current User

Returns the current authenticated user. Type is inferred from:
1. Model/type with `@@auth` attribute, OR
2. Model named `User` (case-sensitive)

```zmodel
// Custom auth type (decoupled from data model)
type AuthInfo {
  email String
  role  String
  @@auth
}

model Post {
  @@allow('all', auth().role == 'ADMIN')
}
```

Without `$setAuth()`, `auth()` returns `null`:

```zmodel
@@deny('all', auth() == null)  // block anonymous
```

### Comparison & Logic

- Comparisons: `==`, `!=`, `>`, `>=`, `<`, `<=`
- Logic: `&&`, `||`, `!`
- Literals: strings, numbers, booleans, null

### Relation Traversal

**To-one relations** — dot notation, chain as deep as needed:

```zmodel
@@allow('all', auth().city == profile.address.city)
```

**To-many relations** — collection predicates:

```zmodel
// Some: at least one matches
@@deny('delete', posts?[published == true])

// Every: all must match
@@allow('read', comments![approved == true])

// None: no items match
@@allow('delete', posts^[published == true])
```

Inside collection predicates, fields resolve against the related model. Use `this` to reference the parent model.

### Policy Functions (from @zenstackhq/plugin-policy)

| Function | Description |
|----------|-------------|
| `auth()` | Current user |
| `now()` | Current datetime |
| `contains(field, search, caseInsensitive?)` | String contains |
| `startsWith(field, search, caseInsensitive?)` | String starts with |
| `endsWith(field, search, caseInsensitive?)` | String ends with |
| `has(field, value)` | List contains value |
| `hasSome(field, values)` | List contains any value |
| `hasEvery(field, values)` | List contains all values |
| `isEmpty(field)` | List is empty |
| `check(relation, operation?)` | Delegate to relation's policies |
| `currentModel(casing?)` | Name of current model |
| `currentOperation(casing?)` | Current operation type |

### check() — Delegate to Relation

```zmodel
model User {
  public Boolean
  @@allow('read', public)
}

model Profile {
  user User
  @@allow('read', check(user, 'read'))
  // Or shorter (infers 'read' from context):
  // @@allow('read', check(user))
}
```

Only supports to-one relations.

## Create Rule Limitations

Create rules evaluate BEFORE the record exists, so only "owned" relations (those with FK in the same model) are accessible:

```zmodel
model Profile {
  user   User @relation(fields: [userId], references: [id])
  userId Int
  @@allow('create', auth().id == user.id)  // ✅ owned relation
}

model User {
  profile Profile
  @@allow('create', auth().id == profile.userId)  // ❌ not owned
}
```

## Field-Level Policies (v3.2.0+, Preview)

Use `@allow` and `@deny` (single `@`) on individual fields:

```zmodel
model User {
  id    Int    @id
  email String @allow('update', auth() == this)
  name  String @deny('read', auth() == null)
}
```

**Restrictions:**
- Only `read` and `update` operations (use `all` for both)
- Cannot be on relation or computed fields

**Read behavior:** Unreadable fields are set to `null` in results (not omitted).

**Update behavior:** Violating field-level update policies throws `ORMError` with `REJECTED_BY_POLICY`.

## Runtime Behavior

### Read Operations

`findMany`, `findUnique`, `count`, etc. only return/involve rows meeting `read` policies.

### Write Operations — Multi-row

`updateMany`, `deleteMany` only affect rows meeting relevant policies.

### Write Operations — Single-row

`update`, `delete` throw `ORMError` with `NOT_FOUND` if target doesn't meet policies.

### Read + Write Interaction

If mutation succeeds but post-mutation entity can't be read, mutation IS persisted but throws `ORMError` with `REJECTED_BY_POLICY`.

### Query Builder

Access control also applies to `$qb`:
- `$qb.selectFrom()` → only readable rows
- `$qb.insertInto()` → ORMError if violates create policies
- `$qb.update()` / `$qb.delete()` → only affects policy-matching rows
- Joins and sub-queries filter to readable rows

### Limitations

- Cascade deletes/updates and DB triggers are NOT controlled
- `$executeRaw()` and `$queryRaw()` bypass access control
- Raw SQL via `sql` tag bypasses access control
