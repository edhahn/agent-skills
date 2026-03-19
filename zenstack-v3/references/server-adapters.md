# ZenStack v3 Server Adapters Reference

ZenStack provides "Query-as-a-Service" — auto-derived CRUD APIs from your data model, served via framework-specific server adapters.

## Architecture

Two main concepts:
1. **API Handler** — processes requests and generates responses (RPC or RESTful)
2. **Server Adapter** — bridges the API handler with a specific web framework

## API Handlers

### RPC API Handler

```typescript
import { RPCApiHandler } from '@zenstackhq/server/api';
import { schema } from '~/zenstack/schema';

const handler = new RPCApiHandler({ schema });
```

### RESTful API Handler

Exposes CRUD as JSON:API v1.1 compliant endpoints:

```typescript
import { RestApiHandler } from '@zenstackhq/server/api';
import { schema } from '~/zenstack/schema';

const handler = new RestApiHandler({
  schema,
  endpoint: 'http://localhost:3000/api',
  pageSize: 100,  // optional, default 100, set Infinity to disable
  modelNameMapping: { User: 'users', Post: 'posts' },  // optional plural URLs
  externalIdMapping: { Tag: 'name' },  // optional natural keys
});
```

#### REST Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/:type` | List resources |
| GET | `/:type/:id` | Fetch single resource |
| GET | `/:type/:id/relationships/:rel` | Fetch relationships |
| GET | `/:type/:id/:rel` | Fetch related resources |
| POST | `/:type` | Create resource |
| PATCH | `/:type/:id` | Update resource |
| DELETE | `/:type/:id` | Delete resource |

#### Query Parameters

- **Filtering**: `filter[field]=value`, `filter[field$gt]=100`, deep: `filter[author][name]=Emily`
- **Sorting**: `sort=createdAt,-viewCount` (prefix `-` for desc)
- **Pagination**: `page[offset]=10&page[limit]=5`
- **Including**: `include=author,comments`, deep: `include=author.profile`
- **Sparse fields**: `fields[post]=title,viewCount`

## Next.js Server Adapter

Package: `@zenstackhq/server/next`

### App Router (Route Handler)

```typescript
// app/api/model/[...path]/route.ts
import type { NextRequest } from 'next/server';
import { NextRequestHandler } from '@zenstackhq/server/next';
import { RPCApiHandler } from '@zenstackhq/server/api';
import { getSessionUser } from '~/auth';
import { client } from '~/db';
import { schema } from '~/zenstack/schema';

const handler = NextRequestHandler({
  apiHandler: new RPCApiHandler({ schema }),
  getClient: (req: NextRequest) => client.$setAuth(getSessionUser(req)),
  useAppDir: true,
});

export {
  handler as GET,
  handler as POST,
  handler as PUT,
  handler as PATCH,
  handler as DELETE,
};
```

### Key Points

- `getClient` is called per-request to return a user-bound ORM client
- Set `useAppDir: true` for App Router
- The `client` should have PolicyPlugin installed for access control

## Express.js Server Adapter

Package: `@zenstackhq/server/express`

```typescript
import { ZenStackMiddleware } from '@zenstackhq/server/express';
import { RPCApiHandler } from '@zenstackhq/server/api';
import express from 'express';
import { schema } from '~/zenstack/schema';

const app = express();
app.use(express.json());

app.use(
  '/api/model',
  ZenStackMiddleware({
    apiHandler: new RPCApiHandler({ schema }),
    getClient: (request) => {
      const uid = request.get('x-userid');
      if (!uid) return client;  // anonymous
      return client.$setAuth({ id: parseInt(uid) });
    },
  })
);
```

## v3 Changes from v2

- API handler must be explicitly passed (was implicit in v2)
- `getPrisma` renamed to `getClient`
- Handler takes `schema` object as input

## Client-Side Hooks (TanStack Query)

v3 uses inference-based hooks (no code generation):

```typescript
import { useClientQueries } from '@zenstackhq/tanstack-query';
import { schema } from '~/zenstack/schema';

function MyComponent() {
  const client = useClientQueries(schema);
  const { data } = client.user.useFindMany({ where: { ... } });
}
```

> SWR support was dropped in v3.
