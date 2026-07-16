# ADR-002: Frontend Integration Boundary

**Status:** Accepted

**Date:** 2026-07-15

## Context

Future public or product frontends (web, mobile, or other clients) will need to interact with Frappe backend capabilities. Without an explicit integration boundary, frontends may couple directly to:

- Frappe DocType internals (schema, field names, validations).
- Database tables or queries.
- Internal server implementation details.

Direct coupling makes backend changes brittle, blocks independent deployment, and prevents versioned evolution of the API surface.

## Decision

Every external frontend **must** be a separate product boundary and **must** integrate with Frappe only through explicit, versioned REST or RPC contracts.

| Aspect | Rule |
|--------|------|
| Integration protocol | Versioned REST (e.g., `/api/v1/<resource>`) or documented RPC. |
| Schema coupling | Frontend consumes a defined request/response contract, never DocType internals. |
| Database coupling | Prohibited — no frontend reads Frappe database tables directly. |
| Contract ownership | The backend team owns the contract; breaking changes require version bump. |
| Independent deployment | Frontend and backend deploy independently, coordinated by contract version. |

## Deferrals

The following are explicitly deferred until the first client frontend is proposed:

- API versioning convention (e.g., URL path vs. header vs. query param).
- Authentication and authorization scheme.
- Error envelope and status code mapping.
- Rate limiting and throttling policy.
- SDK or client library generation.
- API documentation tooling (OpenAPI, etc.).

## Consequences

### Positive

- Backend internals can evolve without breaking frontends.
- Frontends can be developed, tested, and deployed independently.
- Clear contract ownership and governance.
- Multiple frontend types (web, mobile, third-party) share the same contract.

### Negative

- Requires explicit API contract design before frontend implementation.
- Additional overhead for version management and contract testing.
- Frappe's `frappe.hooks` and `frappe.api` patterns must be wrapped behind versioned endpoints.

### Neutral

- Frappe's built-in REST API (`/api/method/...` and `/api/resource/...`) can serve as a starting point but must be versioned and documented.
- GraphQL, gRPC, or other RPC mechanisms are not ruled out but require a separate ADR.

## References

- [ADR-001: Control-Plane Repository Topology](../architecture/control-plane-adr.md)
- [CONTRIBUTING.md](../../CONTRIBUTING.md) — Independent app-repo rule
