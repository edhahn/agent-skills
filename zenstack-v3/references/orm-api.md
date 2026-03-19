# ZenStack v3 ORM API Reference

ZenStack v3's ORM is built on **Kysely** (NOT Prisma). It provides a Prisma-compatible query API on the surface but is a completely independent implementation.

## Client Setup

```typescript
import { ZenStackClient } from '@zenstackhq/orm';
import { SqliteDialect } from '@zenstackhq/orm/dialects/sqlite';
import { PostgresDialect } from '@zenstackhq/orm/dialects/postgres';
import { MysqlDialect } from '@zenstackhq/orm/dialects/mysql';
import { schema } from './zenstack/schema';

// SQLite
import SQLite from 'better-sqlite3';
const db = new ZenStackClient(schema, {
  dialect: new SqliteDialect({ database: new SQLite(':memory:') }),
});

// PostgreSQL
import { Pool } from 'pg';
const db = new ZenStackClient(schema, {
  dialect: new PostgresDialect({
    pool: new Pool({ connectionString: process.env.DATABASE_URL }),
  }),
});
```

**Key difference from Prisma:** No bundled DB driver. You install and configure the driver yourself. No connection string from schema — pass connection info at client creation.

### Type Inference

```typescript
import type { ClientContract } from '@zenstackhq/orm';
import type { SchemaType } from '@/zenstack/schema';
type DbClient = ClientContract<SchemaType>;
```

## Find Operations

### Methods

| Method | Description |
|--------|-------------|
| `findMany` | Multiple records matching criteria |
| `findUnique` | Single record by unique criteria |
| `findFirst` | First record matching criteria |
| `findUniqueOrThrow` | Like findUnique, throws if not found |
| `findFirstOrThrow` | Like findFirst, throws if not found |
| `exists` | (v3.2.0+) Check existence, more efficient than findFirst |

### Basic Usage

```typescript
// findMany with where clause
const posts = await db.post.findMany({
  where: { published: true },
  orderBy: { createdAt: 'desc' },
  include: { author: true },
});

// findUnique by id or unique field
const user = await db.user.findUnique({ where: { id: 1 } });
const user2 = await db.user.findUnique({ where: { email: 'alice@test.com' } });

// findFirst (non-unique filter)
const post = await db.post.findFirst({ where: { published: true } });
```

### Field Selection

```typescript
// select specific fields + relations
await db.post.findMany({
  select: { title: true, author: { select: { name: true } } },
});

// include relations (all scalar fields + specified relations)
await db.post.findMany({
  include: { author: true },
});

// omit fields
await db.post.findMany({
  omit: { content: true },
  include: { author: true },
});

// select _count of to-many relations
await db.user.findFirst({
  select: { email: true, _count: true },
});
```

> `select` and `include` are mutually exclusive. `select` and `omit` are mutually exclusive.

### Sorting

```typescript
// Simple sort
await db.post.findMany({ orderBy: { viewCount: 'asc' } });

// Multiple fields
await db.post.findMany({ orderBy: { published: 'asc', viewCount: 'desc' } });

// Sort by relation field
await db.post.findMany({ orderBy: { author: { email: 'desc' } } });

// Sort by relation count
await db.user.findMany({ orderBy: { posts: { _count: 'desc' } } });

// Null handling
await db.post.findMany({
  orderBy: { authorId: { sort: 'asc', nulls: 'first' } },
});
```

### Pagination

```typescript
// Offset-based
await db.post.findMany({ orderBy: { viewCount: 'desc' }, skip: 1, take: 2 });

// Backward (negative take)
await db.post.findMany({ orderBy: { viewCount: 'asc' }, take: -2 });

// Cursor-based
await db.post.findMany({ orderBy: { id: 'asc' }, cursor: { id: 2 }, skip: 1 });
```

### Distinct

```typescript
// PostgreSQL only (uses DISTINCT ON)
await db.post.findMany({ distinct: ['authorId'] });
```

## Filtering

### Basic Operators

```typescript
// Value equality
await db.post.findMany({ where: { title: 'Post1' } });
// Explicit equals
await db.post.findMany({ where: { title: { equals: 'Post1' } } });

// String operators
where: { content: { contains: 'hello' } }
where: { content: { startsWith: 'Hello' } }
where: { content: { endsWith: 'world' } }

// Numeric operators
where: { viewCount: { gt: 1 } }
where: { viewCount: { gte: 1 } }
where: { viewCount: { lt: 10 } }
where: { viewCount: { lte: 10 } }
where: { viewCount: { between: [1, 10] } }

// Not
where: { viewCount: { not: { gt: 1 } } }

// In / NotIn
where: { title: { in: ['Post1', 'Post2'] } }
where: { title: { notIn: ['Draft'] } }
```

### Logical Operators

```typescript
where: {
  OR: [
    { viewCount: { gt: 1 } },
    { AND: [{ content: { startsWith: 'A' } }, { NOT: { title: 'Post1' } }] }
  ]
}
```

### List Filters (PostgreSQL only)

```typescript
where: { topics: { has: 'webdev' } }
where: { topics: { hasSome: ['webdev', 'typescript'] } }
where: { topics: { hasEvery: ['webdev', 'typescript'] } }
where: { topics: { isEmpty: true } }
```

### Relation Filters

```typescript
// To-one: filter by relation fields directly
where: { author: { email: 'u1@test.com' } }
where: { author: null }  // no relation

// To-many: some, every, none
where: { posts: { some: { published: true } } }
where: { posts: { every: { published: true } } }
where: { posts: { none: { published: true } } }
```

### JSON Filters

```typescript
// Generic JSON (path-based)
where: { profile: { path: '$.professions[0]', string_starts_with: 'eng' } }

// Typed JSON (structured, like relations)
where: { profile: { age: { gt: 18 } } }
where: { profile: { jobs: { some: { title: { contains: 'Dev' } } } } }
```

### Query Builder in Filters ($expr)

Mix Kysely query builder into ORM filters:

```typescript
await db.user.findMany({
  where: {
    $expr: (eb) =>
      eb.selectFrom('Post')
        .whereRef('Post.authorId', '=', 'User.id')
        .select(({ fn }) => eb(fn.countAll(), '>=', 2).as('hasMorePosts'))
  }
});
```

## Create Operations

```typescript
// Create with nested relations
const user = await db.user.create({
  data: {
    email: 'u1@test.com',
    posts: {
      create: [
        { title: 'Post1', published: false },
        { title: 'Post2', published: true },
      ]
    }
  },
  include: { posts: true },
});

// Connect to existing entity
await db.post.create({
  data: { title: 'Post3', author: { connect: { id: 1 } } }
});

// createMany (returns { count })
await db.user.createMany({
  data: [{ email: 'u4@test.com' }, { email: 'u5@test.com' }]
});

// createManyAndReturn (returns created entities)
await db.user.createManyAndReturn({
  data: [{ email: 'u6@test.com' }],
  skipDuplicates: true,
});
```

## Update Operations

```typescript
// Update with relation manipulation
await db.user.update({
  where: { id: 1 },
  data: {
    posts: {
      create: { title: 'New Post' },      // create nested
      connect: { id: 2 },                  // connect existing
      disconnect: { id: 3 },               // disconnect
      update: { where: { id: 1 }, data: { title: 'Updated' } },
      delete: { id: 4 },                   // delete nested
      upsert: {
        where: { id: 5 },
        create: { title: 'New' },
        update: { title: 'Updated' },
      },
    }
  },
  include: { posts: true },
});

// updateMany
await db.post.updateMany({
  where: { published: false },
  data: { published: true },
});
```

## Delete Operations

```typescript
// Delete unique
await db.post.delete({ where: { id: 1 } });

// Delete many
await db.post.deleteMany({ where: { published: false } });
```

## Transactions

```typescript
// Sequential (batched)
const [u1, u2] = await db.$transaction([
  db.user.create({ data: { email: 'u1@test.com' } }),
  db.user.create({ data: { email: 'u2@test.com' } }),
]);

// Interactive
const [user, post] = await db.$transaction(async (tx) => {
  const user = await tx.user.create({ data: { email: 'u3@test.com' } });
  const post = await tx.post.create({ data: { title: 'Post1', authorId: user.id } });
  return [user, post];
});
```

## Computed Fields

Defined in schema + implemented with Kysely at client creation:

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

// Use like normal fields
await db.user.findFirst({ where: { postCount: { gt: 1 } }, orderBy: { postCount: 'desc' } });
await db.user.aggregate({ _avg: { postCount: true } });
```

Computed fields are evaluated **on the database side** (not client-side like Prisma extensions).

## Query Builder API ($qb)

Full Kysely query builder access when ORM API is insufficient:

```typescript
// Insert
const user = await db.$qb
  .insertInto('User')
  .values({ email: 'u1@test.com' })
  .returningAll()
  .executeTakeFirstOrThrow();

// Complex query with joins
const result = await db.$qb
  .selectFrom('User')
  .leftJoin(
    eb => eb.selectFrom('Post')
      .select('authorId')
      .select(({ fn }) => fn.countAll().as('postCount'))
      .groupBy('authorId')
      .as('UserPosts'),
    join => join.onRef('UserPosts.authorId', '=', 'User.id')
  )
  .selectAll('User')
  .select('postCount')
  .where('postCount', '>', 1)
  .executeTakeFirstOrThrow();
```

The query builder is **also subject to access control** when the PolicyPlugin is installed.

## Raw SQL

```typescript
await db.$executeRaw`...`;
await db.$queryRaw`...`;
```

> Raw queries bypass access control enforcement.
