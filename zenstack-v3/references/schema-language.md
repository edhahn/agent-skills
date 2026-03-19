# ZenStack v3 Schema Language Reference

ZenStack uses **ZModel**, a superset of [Prisma Schema Language (PSL)](https://www.prisma.io/docs/orm/prisma-schema). Every valid Prisma schema is valid ZModel. ZModel adds access control, mixins, polymorphism, typed JSON, and plugins.

> **v3 key change**: ZModel replaces PSL's `generator` with a `plugin` construct. No `prisma-client-js` generator needed.

## Basic Schema Structure

```zmodel
// zenstack/schema.zmodel
datasource db {
  provider = "postgresql"   // postgresql, mysql, sqlite
  url      = env("DATABASE_URL")
}

model User {
  id    Int    @id @default(autoincrement())
  email String @unique
  name  String
  posts Post[]
}

model Post {
  id        Int      @id @default(autoincrement())
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  title     String
  content   String?
  published Boolean  @default(false)
  author    User     @relation(fields: [authorId], references: [id])
  authorId  Int
}
```

## Models

Models represent domain entities backed by database tables. Must have a unique identifier.

### Identity

```zmodel
// Single field ID
model User {
  id Int @id
}

// Composite ID
model City {
  country String
  name    String
  @@id([country, name])
}

// Unique as identifier (fallback when no @id)
model User {
  email String @unique
}
```

### Field Types

- **Built-in**: `String`, `Boolean`, `Int`, `BigInt`, `Float`, `Decimal`, `DateTime`, `Json`, `Bytes`, `Unsupported`
- **Enum**: defined enum types
- **Model**: creates a relation
- **Custom type**: for typed JSON fields

### Modifiers

- `?` = optional: `name String?`
- `[]` = list: `tags String[]`
- Cannot combine `?` and `[]`

### Default Values

```zmodel
model User {
  id        Int      @id @default(autoincrement())
  role      Role     @default(USER)
  createdAt DateTime @default(now())
  uid       String   @id @default(uuid())
  cid       String   @id @default(cuid())
  nano      String   @id @default(nanoid())
  ulid      String   @id @default(ulid())
  raw       String   @default(dbgenerated("gen_random_uuid()"))
}
```

### Custom ID Formats (v3.1.0+)

```zmodel
model User {
  // UUID with "user_" prefix
  id String @id @default(uuid(4, "user_%s"))
}
```

### Native Type Mapping

```zmodel
model User {
  name String @db.VarChar(64)
}
```

### Name Mapping

```zmodel
model User {
  id Int @id @map('_id')
  @@map('users')
}
```

## Enums

```zmodel
enum Role {
  USER
  ADMIN
}

model User {
  id   Int  @id
  role Role @default(USER)
}
```

Enum field names are global scope — no qualification needed, but avoid name collisions.

## Relations

### One-to-One

```zmodel
model User {
  id      Int      @id
  profile Profile?  // non-owner must be optional
}

model Profile {
  id     Int  @id
  user   User @relation(fields: [userId], references: [id])
  userId Int  @unique
}
```

### One-to-Many

```zmodel
model User {
  id    Int    @id
  posts Post[]
}

model Post {
  id       Int  @id
  author   User @relation(fields: [authorId], references: [id])
  authorId Int
}
```

### Many-to-Many (Implicit)

```zmodel
model User {
  id    Int    @id
  posts Post[]
}

model Post {
  id      Int    @id
  editors User[]
}
// Auto-creates _PostToUser join table
```

### Many-to-Many (Explicit)

```zmodel
model UserPost {
  userId Int
  postId Int
  user   User @relation(fields: [userId], references: [id])
  post   Post @relation(fields: [postId], references: [id])
  @@id([userId, postId])
}
```

### Referential Actions

```zmodel
model Profile {
  user User @relation(fields: [userId], references: [id],
    onUpdate: Cascade, onDelete: Cascade)
  userId String @unique
}
// Options: Cascade, Restrict, NoAction, SetNull, SetDefault
```

### Self Relations

```zmodel
model Employee {
  id            Int        @id
  managerId     Int?
  manager       Employee?  @relation('Management', fields: [managerId], references: [id])
  subordinates  Employee[] @relation('Management')
}
```

## Attributes

- Field-level: `@` prefix (e.g., `@id`, `@unique`, `@default()`)
- Model-level: `@@` prefix (e.g., `@@id()`, `@@unique()`, `@@index()`)

ZModel allows custom attribute definitions (unlike Prisma).

```zmodel
// Built-in attribute usage
model A {
  id Int @id
  x  String
  @@index([x])
  @@index([x], name: 'custom_index')
}
```

## Mixins (replaces v2 "abstract model")

Share common fields across models without DB-level existence:

```zmodel
type Timestamped {
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model User with Timestamped {
  id    String @id
  email String @unique
}

model Post with Timestamped {
  id    String @id
  title String
}
```

- Use `type` to define (not `abstract model` as in v2)
- Use `with` keyword (not `extends` as in v2)
- A model can use multiple mixins
- Mixin fields are inlined into models

## Polymorphism (Multi-Table Inheritance)

ZModel-only feature. Uses `@@delegate` for MTI pattern:

```zmodel
model User {
  id       Int       @id
  contents Content[]
}

model Content {
  id        Int      @id
  name      String
  createdAt DateTime @default(now())
  owner     User     @relation(fields: [ownerId], references: [id])
  ownerId   Int
  type      String   // discriminator field

  @@delegate(type)   // marks as polymorphic base
}

model Post extends Content {
  content String
}

model Image extends Content {
  data Bytes
}

model Video extends Content {
  url String
}
```

**Key points:**
- Discriminator field must be `String` or enum type
- `@@delegate(type)` marks base model and designates discriminator
- Deep hierarchies supported (each level needs own discriminator + `@@delegate`)
- No multiple base model inheritance
- ORM auto-creates base record when creating concrete; queries return concrete fields
- Base and concrete share same ID values

## Strongly Typed JSON

```zmodel
type Address {
  street  String
  city    String
  country String
  zip     Int
}

model User {
  id      Int     @id
  address Address @json
}
```

- `@json` attribute marks the field (for readability; indicates JSON not relation)
- Migration engine sees plain JSON; ORM enforces structure and types results
- Custom types can be nested and used in arrays

## Plugins

Replaces Prisma's `generator` concept. Preview feature.

```zmodel
plugin policy {
  provider = '@zenstackhq/plugin-policy'
}

plugin prisma {
  provider = '@core/prisma'
  output   = '../prisma/schema.prisma'
}

plugin typescript {
  provider = '@core/typescript'
  output   = '../generated'
}

plugin myPlugin {
  provider = 'my-zenstack-plugin'
  output   = './generated'
}
```

**Plugin effects:**
- Contribute custom attributes and functions to ZModel
- Generate code on `zen generate`
- Extend CLI and ORM runtime behavior

## Datasource

```zmodel
datasource db {
  provider = "postgresql"  // postgresql, mysql, sqlite
  url      = env("DATABASE_URL")
}
```

> **v3 limitation**: Only PostgreSQL, MySQL, and SQLite supported.

## String Literals

ZModel allows both single quotes and double quotes (unlike Prisma which only allows double).
