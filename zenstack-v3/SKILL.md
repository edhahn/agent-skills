---
name: zenstack-v3
description: >
  ZenStack v3 schema-first ORM for TypeScript. Use when working with ZModel schemas,
  ZenStack ORM CRUD operations, access control policies (@@allow/@@deny), database
  migrations, server adapters (Next.js, Express), runtime plugins, computed fields,
  polymorphism, typed JSON, or migrating from Prisma/ZenStack v2. Triggers on:
  ZModel, ZenStack, zenstack, .zmodel files, @@allow, @@deny, auth(), PolicyPlugin,
  ZenStackClient, @zenstackhq/orm, zen generate, zen migrate.
---

# ZenStack v3 — AI Coding Agent Skill

## Critical Context

**ZenStack v3 is a COMPLETE REWRITE.** It removed Prisma as a runtime dependency and built
its own ORM on [Kysely](https://kysely.dev/). The schema language remains a "Prisma superset"
but the runtime is entirely different.

**Do NOT confuse with v2:**
- v2 used `@zenstackhq/runtime` → v3 uses `@zenstackhq/orm`
- v2 CLI was `zenstack` package → v3 is `@zenstackhq/cli`
- v2 had `abstract model` → v3 uses `type` + `with` (mixins)
- v2 used `enhance(prisma, ...)` → v3 uses `db.$use(new PolicyPlugin())`
- v2 generated into node_modules → v3 generates to `zenstack/` folder

**Supported databases:** PostgreSQL, MySQL, SQLite only.

## Quick Start

### Installation

```bash
npm install @zenstackhq/schema @zenstackhq/orm
npm install --save-dev @zenstackhq/cli
# Plus a database driver:
npm install better-sqlite3  # or pg, mysql2
```

### Minimal Schema

```zmodel
// zenstack/schema.zmodel
datasource db {
  provider = 'sqlite'
  url      = 'file:./dev.db'
}

model User {
  id    Int    @id @default(autoincrement())
  email String @unique
  posts Post[]
}

model Post {
  id        Int      @id @default(autoincrement())
  title     String
  published Boolean  @default(false)
  author    User     @relation(fields: [authorId], references: [id])
  authorId  Int
}
```

### Generate & Create Client

```bash
npx zen generate
```

```typescript
import { ZenStackClient } from '@zenstackhq/orm';
import { SqliteDialect } from '@zenstackhq/orm/dialects/sqlite';
import SQLite from 'better-sqlite3';
import { schema } from './zenstack/schema';

export const db = new ZenStackClient(schema, {
  dialect: new SqliteDialect({ database: new SQLite('./dev.db') }),
});
```

### Basic CRUD

```typescript
// Create
const user = await db.user.create({
  data: { email: 'alice@test.com', posts: { create: { title: 'Hello' } } },
  include: { posts: true },
});

// Read
const posts = await db.post.findMany({
  where: { published: true },
  orderBy: { createdAt: 'desc' },
  include: { author: true },
});

// Update
await db.post.update({
  where: { id: 1 },
  data: { published: true },
});

// Delete
await db.post.delete({ where: { id: 1 } });

// Transaction
const [u, p] = await db.$transaction(async (tx) => {
  const u = await tx.user.create({ data: { email: 'bob@test.com' } });
  const p = await tx.post.create({ data: { title: 'Hi', authorId: u.id } });
  return [u, p];
});
```

## Access Control

### Setup

```bash
npm install @zenstackhq/plugin-policy
```

```zmodel
plugin policy {
  provider = '@zenstackhq/plugin-policy'
}

model Post {
  id        Int     @id @default(autoincrement())
  title     String
  published Boolean @default(false)
  author    User    @relation(fields: [authorId], references: [id])
  authorId  Int

  @@deny('all', auth() == null)
  @@allow('read', published)
  @@allow('all', auth().id == authorId)
}
```

### Runtime

```typescript
import { PolicyPlugin } from '@zenstackhq/plugin-policy';

const authDb = db.$use(new PolicyPlugin());
const userDb = authDb.$setAuth({ id: currentUserId });
// All queries on userDb enforce access policies
```

**Evaluation:** deny wins → allow wins → denied by default.

**Operations:** `create`, `read`, `update`, `post-update`, `delete`, `all` (excludes post-update).

### Key Functions

- `auth()` — current user (type from `@@auth` model or `User` model)
- `check(relation, operation?)` — delegate to relation's policies
- `now()` — current datetime
- Collection predicates: `relation?[cond]` (some), `relation![cond]` (every), `relation^[cond]` (none)

## Schema Patterns

### Mixins

```zmodel
type Timestamped {
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model Post with Timestamped {
  id    Int    @id @default(autoincrement())
  title String
}
```

### Polymorphism (MTI)

```zmodel
model Content {
  id   Int    @id @default(autoincrement())
  name String
  type String
  @@delegate(type)
}

model Post extends Content {
  body String
}

model Video extends Content {
  url String
}
```

### Typed JSON

```zmodel
type Address {
  street String
  city   String
  zip    Int
}

model User {
  id      Int     @id
  address Address @json
}
```

### Computed Fields

```zmodel
model User {
  id        Int @id
  postCount Int @computed
}
```

```typescript
const db = new ZenStackClient(schema, {
  dialect: ...,
  computedFields: {
    User: {
      postCount: (eb) =>
        eb.selectFrom('Post')
          .whereRef('Post.authorId', '=', 'id')
          .select(({ fn }) => fn.countAll<number>().as('count')),
    },
  },
});
```

## Query Builder ($qb)

Escape hatch to full Kysely when ORM API isn't enough:

```typescript
const result = await db.$qb
  .selectFrom('User')
  .leftJoin('Post', 'Post.authorId', 'User.id')
  .select(['User.id', 'User.email', 'Post.title'])
  .execute();
```

Mix into ORM filters with `$expr`:

```typescript
await db.user.findMany({
  where: {
    $expr: (eb) =>
      eb.selectFrom('Post')
        .whereRef('Post.authorId', '=', 'User.id')
        .select(({ fn }) => eb(fn.countAll(), '>=', 2).as('v'))
  }
});
```

## Server Adapters

### Next.js (App Router)

```typescript
// app/api/model/[...path]/route.ts
import { NextRequestHandler } from '@zenstackhq/server/next';
import { RPCApiHandler } from '@zenstackhq/server/api';
import { schema } from '~/zenstack/schema';

const handler = NextRequestHandler({
  apiHandler: new RPCApiHandler({ schema }),
  getClient: (req) => authDb.$setAuth(getSessionUser(req)),
  useAppDir: true,
});

export { handler as GET, handler as POST, handler as PUT, handler as PATCH, handler as DELETE };
```

### Express.js

```typescript
import { ZenStackMiddleware } from '@zenstackhq/server/express';
import { RPCApiHandler } from '@zenstackhq/server/api';

app.use('/api/model', ZenStackMiddleware({
  apiHandler: new RPCApiHandler({ schema }),
  getClient: (req) => authDb.$setAuth(getUser(req)),
}));
```

## CLI Commands

| Command | Purpose |
|---------|---------|
| `zen generate` | Compile ZModel → TypeScript |
| `zen db push` | Push schema to DB (dev only) |
| `zen db pull` | Introspect DB → ZModel |
| `zen migrate dev` | Create + apply migration (dev) |
| `zen migrate deploy` | Apply pending migrations (prod) |
| `zen migrate reset` | Drop + reapply all (dev only) |
| `zen migrate status` | Check migration status |

## Plugins

### Schema Plugins

```zmodel
plugin policy {
  provider = '@zenstackhq/plugin-policy'
}

plugin prisma {
  provider = '@core/prisma'
  output   = '../prisma/schema.prisma'
}
```

### Runtime Plugins

```typescript
const enhanced = db.$use({
  id: 'my-plugin',
  onQuery: {
    $allModels: {
      async $allOperations({ args, proceed }) {
        console.log('query intercepted');
        return proceed(args);
      },
    },
  },
});
```

Hook types: Query API hooks, Entity mutation hooks, Kysely query hooks.

## Reference Files

For detailed documentation, see:
- `references/schema-language.md` — models, relations, enums, attributes, mixins, polymorphism, typed JSON
- `references/access-control.md` — policies, auth(), field-level policies, runtime behavior
- `references/orm-api.md` — CRUD, filters, transactions, computed fields, query builder
- `references/plugins-and-cli.md` — plugin system, CLI commands, code generation
- `references/server-adapters.md` — Next.js, Express, REST API, client-side hooks
- `references/migration.md` — migrating from Prisma and from v2

## Common Gotchas

1. **No Prisma at runtime** — don't import from `@prisma/client`
2. **Install DB driver yourself** — ZenStack doesn't bundle drivers
3. **`$use()` and `$setAuth()` return new clients** — they're immutable
4. **Raw SQL bypasses access control** — `$executeRaw`, `$queryRaw`, `sql` tag
5. **Cascade deletes/triggers bypass access control** — DB-internal operations
6. **`select` and `include` are mutually exclusive** — can't use both
7. **`post-update` must be explicit** — `all` doesn't include it
8. **v3 generates to `zenstack/` folder** — not into `node_modules`
9. **Computed fields are DB-side** — not client-side like Prisma extensions
10. **Only PostgreSQL, MySQL, SQLite** — no MongoDB, CockroachDB, etc.
11. **Use multiple schema files** — use a zmodel file per model/enum/type in a ./schema folder
12. **Zmodel files allow circular imports** - don't worry about circular imports in zmodel
