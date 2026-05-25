#!/usr/bin/env bash
set -euo pipefail

REPO="marcusmourao/studies"
ISSUES_DIR="$(mktemp -d)"
trap 'rm -rf "$ISSUES_DIR"' EXIT

create_label() {
  gh label create "$1" --color "$2" --description "$3" --repo "$REPO" 2>/dev/null || true
}

create_milestone() {
  gh api repos/marcusmourao/studies/milestones \
    -f title="$1" \
    -f description="$2" \
    -f state=open 2>/dev/null || true
}

get_issue_id() {
  gh api graphql -f query='
    query($owner: String!, $name: String!, $number: Int!) {
      repository(owner: $owner, name: $name) {
        issue(number: $number) { id }
      }
    }' \
    -f owner=marcusmourao \
    -f name=studies \
    -F number="$1" \
    --jq '.data.repository.issue.id'
}

link_sub_issue() {
  gh api graphql -f query='
    mutation($issueId: ID!, $subIssueId: ID!) {
      addSubIssue(input: { issueId: $issueId, subIssueId: $subIssueId }) {
        issue { number }
      }
    }' \
    -f issueId="$1" \
    -f subIssueId="$2" >/dev/null
}

write_body() {
  local file="$1"
  shift
  cat > "$file" <<EOF
$*
EOF
}

echo "Creating labels..."
create_label "epic" "6f42c1" "Parent tracking issue"
create_label "phase" "1d76db" "Roadmap phase sub-issue"
create_label "type:feature" "0e8a16" "Domain feature work"
create_label "type:infra" "d4c5f9" "Infrastructure and platform"
create_label "type:quality" "fbca04" "Testing, CI, performance"
create_label "type:async" "d93f0b" "Queues, workers, async patterns"
create_label "type:security" "b60205" "Authentication and authorization"
create_label "type:docs" "0075ca" "Documentation and ADRs"
create_label "status:blocked" "ee0701" "Blocked by dependency"
create_label "good first issue" "7057ff" "Good entry point for contributors"

echo "Creating milestones..."
create_milestone "M1 — Foundation" "Phases 1–2: Bootstrap and schema"
create_milestone "M2 — Core Domain" "Phases 3–5: Business logic and transactions"
create_milestone "M3 — Quality & Ops" "Phases 6–12: Tests, logs, metrics, auth, Docker, K8s, CI"
create_milestone "M4 — Async Platform" "Phases 13–18: Queues, workers, reliability patterns"
create_milestone "M5 — Advanced Features" "Phases 19–23: Reports, audit, GraphQL, AI, performance"
create_milestone "M6 — Engineering Maturity" "Phases 24–25: ADRs and runbooks"

cat > "$ISSUES_DIR/epic.md" <<'EOF'
# Mini ERP — Backend Engineering Roadmap

> **Goal:** Become a strong fullstack/backend engineer by building a production-minded system and learning software engineering practices progressively.

## Vision

Build a backend platform for small business operations that covers real-world concerns: transactions, concurrency, async processing, observability, security, and operational maturity — not just CRUD.

## Scope

- Customers, Products, Inventory, Orders, Reports
- Audit System, Authentication & Authorization
- Async Processing (queues, workers, DLQ, outbox, idempotency)
- GraphQL (reads) + REST (writes)
- AI Assistant Integration (tool-calling only)

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Kotlin |
| Framework | Spring Boot |
| Database | PostgreSQL + Flyway |
| ORM | Spring Data JPA (Hibernate) |
| Async | Redis |
| Security | Spring Security + JWT |
| Observability | Micrometer + Spring Actuator |
| Infra | Docker + Kubernetes |
| Testing | JUnit 5, MockK, Testcontainers |

## Architecture

```text
Clients
 ├── REST API
 └── GraphQL API

Backend
 ├── Customers / Products / Inventory / Orders
 ├── Reports / Audit / Auth
 ├── Async Workers / AI Assistant

Infrastructure
 ├── PostgreSQL / Redis Queue
 └── Logs / Metrics / Workers
```

## API Standards

- Versioning: `/api/v1/...`
- Pagination: `?page=0&size=20&sort=createdAt,desc`
- Error format: `{ "code": "...", "message": "..." }`
- Correlation header: `X-Correlation-ID`

## Key Architectural Decisions

- **Monolith first** — simpler deployment, transactions, debugging; modular boundaries preserved
- **Pessimistic locking** — inventory consistency over throughput
- **Outbox pattern** — reliable DB + queue consistency
- **REST + GraphQL** — REST for writes/transactions; GraphQL for read-heavy queries
- **Redis queues** — simpler setup; enough for async concepts before Kafka/RabbitMQ
- **Idempotent workers** — retries are inevitable; avoid duplicate side effects

## Sub-Issues Tracker

_Sub-issue links will be added after creation._

## Success Criteria

- [ ] Backend engineering fundamentals demonstrated
- [ ] Transactions & concurrency handled correctly
- [ ] Distributed systems basics (queues, outbox, DLQ, idempotency)
- [ ] Observability (logs, metrics, correlation IDs)
- [ ] Security (JWT + RBAC)
- [ ] Infrastructure (Docker, Kubernetes, CI)
- [ ] API design (REST + GraphQL)
- [ ] AI integration patterns (tool-calling, no direct DB writes)
- [ ] Operational maturity (runbooks, ADRs, load testing)

## How to Contribute

1. Pick an open sub-issue (respect dependencies)
2. Implement in a feature branch
3. Open a PR with `Closes #N` referencing the sub-issue
4. One PR per sub-issue is the default

## Reference

Full roadmap: [`project.md`](https://github.com/marcusmourao/studies/blob/main/project.md)
EOF

# Phase bodies
write_body "$ISSUES_DIR/01.md" "## Goal

Bootstrap the Spring Boot project with environments, validation, exception handling, and base package structure.

## Tasks

- [ ] Initialize Spring Boot project
- [ ] Configure Gradle
- [ ] Configure profiles: dev, test, prod
- [ ] Setup validation
- [ ] Setup exception handling
- [ ] Base package structure (\`common\`, \`customers\`, \`products\`, \`inventory\`, \`orders\`, \`reports\`, \`audit\`, \`auth\`, \`graphql\`, \`ai\`)

## Acceptance Criteria

- [ ] App starts with dev/test/prod profiles
- [ ] Global exception handler returns standard error format
- [ ] Package structure matches roadmap
- [ ] Validation framework configured

## Depends on

None — starting point.

## References

- \`project.md\` — Phase 1"

write_body "$ISSUES_DIR/02.md" "## Goal

Establish reproducible schema evolution with Flyway migrations and required indexes.

## Tasks

- [ ] Add Flyway
- [ ] Disable ddl-auto
- [ ] Create migrations for: users, customers, products, inventory, orders, order_items, audit_logs, processed_events, outbox_events
- [ ] Add indexes: orders(created_at), orders(customer_id), inventory(product_id), audit_logs(entity_id), processed_events(event_id)

## Acceptance Criteria

- [ ] Schema created exclusively via Flyway migrations
- [ ] All tables and indexes exist
- [ ] Migrations run cleanly on fresh database

## Depends on

- Phase 1

## References

- \`project.md\` — Phase 2"

write_body "$ISSUES_DIR/03.md" "## Goal

Implement full customer management with validations, pagination, and filtering.

## Tasks

- [ ] POST /api/v1/customers
- [ ] GET /api/v1/customers (pagination + filtering)
- [ ] GET /api/v1/customers/{id}
- [ ] PUT /api/v1/customers/{id}
- [ ] DELETE /api/v1/customers/{id}
- [ ] Validations: valid email, unique email, non-empty name
- [ ] Status codes: 201, 400, 404, 409

## Acceptance Criteria

- [ ] All CRUD endpoints working
- [ ] Email uniqueness enforced
- [ ] Pagination follows API standard

## Depends on

- Phase 2

## References

- \`project.md\` — Phase 3"

write_body "$ISSUES_DIR/04.md" "## Goal

Implement product management and inventory with stock consistency rules.

## Tasks

- [ ] POST /api/v1/products
- [ ] GET /api/v1/products
- [ ] GET /api/v1/products/{id}
- [ ] PATCH /api/v1/inventory/{productId}/adjust
- [ ] Stock cannot go negative
- [ ] Inventory auto-created with product
- [ ] Inventory consistency maintained

## Acceptance Criteria

- [ ] Products CRUD working
- [ ] Inventory adjustment rejects negative stock
- [ ] Inventory row created automatically for new products

## Depends on

- Phase 2

## References

- \`project.md\` — Phase 4"

write_body "$ISSUES_DIR/05.md" "## Goal

Implement atomic order creation with inventory locking and stock deduction.

## Tasks

- [ ] POST /api/v1/orders
- [ ] GET /api/v1/orders
- [ ] GET /api/v1/orders/{id}
- [ ] Transaction flow: validate customer → validate products → lock inventory → validate stock → deduct → persist order → persist outbox event → commit
- [ ] Pessimistic locking on inventory rows
- [ ] Any failure rolls back; transactions kept short

## Acceptance Criteria

- [ ] Order creation is atomic
- [ ] Stock never goes negative under concurrent requests
- [ ] Outbox event persisted in same transaction

## Depends on

- Phase 3, Phase 4

## References

- \`project.md\` — Phase 5"

write_body "$ISSUES_DIR/06.md" "## Goal

Guarantee correctness with unit, integration, and transactional concurrency tests.

## Tasks

- [ ] Unit tests for business rules and services
- [ ] Integration tests with real DB (Testcontainers)
- [ ] Endpoint flow tests
- [ ] Transactional tests: rollback, stock consistency, concurrency
- [ ] Concurrency scenario: 50 concurrent requests, same product, stock never negative

## Acceptance Criteria

- [ ] Test suite runs in CI
- [ ] Concurrency test proves stock integrity
- [ ] Rollback behavior verified

## Depends on

- Phase 5

## References

- \`project.md\` — Phase 6"

write_body "$ISSUES_DIR/07.md" "## Goal

Enable production debugging with structured logging for key events.

## Tasks

- [ ] Log order creation, failures, retries, authentication failures
- [ ] Structured logs preferred
- [ ] Avoid logging sensitive data

## Acceptance Criteria

- [ ] Key business events logged with structured format
- [ ] No passwords/tokens in logs
- [ ] Log format suitable for aggregation

## Depends on

- Phase 1

## References

- \`project.md\` — Phase 7"

write_body "$ISSUES_DIR/08.md" "## Goal

Understand system behavior via metrics and end-to-end correlation ID propagation.

## Tasks

- [ ] Metrics: request duration, orders_created_total, orders_failed_total
- [ ] X-Correlation-ID header support
- [ ] Propagate correlation ID through logs, queues, workers

## Acceptance Criteria

- [ ] Actuator metrics exposed
- [ ] Correlation ID present in logs for traced requests
- [ ] Custom order metrics registered

## Depends on

- Phase 7

## References

- \`project.md\` — Phase 8"

write_body "$ISSUES_DIR/09.md" "## Goal

Secure the API with JWT authentication and role-based access control.

## Tasks

- [ ] JWT auth implementation
- [ ] RBAC with ADMIN and USER roles
- [ ] ADMIN: manage products, adjust inventory
- [ ] USER: create orders

## Acceptance Criteria

- [ ] Unauthenticated requests rejected on protected endpoints
- [ ] Role restrictions enforced
- [ ] Auth failures logged

## Depends on

- Phase 1

## References

- \`project.md\` — Phase 9"

write_body "$ISSUES_DIR/10.md" "## Goal

Provide reproducible local development with Docker containers.

## Tasks

- [ ] Dockerfile for app
- [ ] docker-compose.yml with app, postgres, redis
- [ ] Document local startup

## Acceptance Criteria

- [ ] \`docker compose up\` starts full stack
- [ ] App connects to postgres and redis
- [ ] Migrations run on startup

## Depends on

- Phase 1

## References

- \`project.md\` — Phase 10"

write_body "$ISSUES_DIR/11.md" "## Goal

Learn orchestration basics with Kubernetes manifests.

## Tasks

- [ ] Deployment manifest
- [ ] Service manifest
- [ ] ConfigMap
- [ ] Secret

## Acceptance Criteria

- [ ] App deployable to local/minikube cluster
- [ ] Config and secrets externalized
- [ ] Service exposes app correctly

## Depends on

- Phase 10

## References

- \`project.md\` — Phase 11"

write_body "$ISSUES_DIR/12.md" "## Goal

Enforce code quality and automate verification via CI pipeline.

## Tasks

- [ ] Formatter
- [ ] Linter
- [ ] Static analysis
- [ ] GitHub Actions pipeline: build → lint → tests → integration tests

## Acceptance Criteria

- [ ] CI runs on every PR
- [ ] Pipeline fails on lint/test failures
- [ ] Integration tests included

## Depends on

- Phase 6

## References

- \`project.md\` — Phase 12"

write_body "$ISSUES_DIR/13.md" "## Goal

Decouple heavy processing from synchronous request path.

## Tasks

- [ ] Identify async use cases: reports, analytics, audit processing
- [ ] Design async job interfaces
- [ ] Trigger async jobs from domain events

## Acceptance Criteria

- [ ] Heavy operations no longer block API responses
- [ ] Async job contracts defined
- [ ] Report generation runs asynchronously

## Depends on

- Phase 5

## References

- \`project.md\` — Phase 13"

write_body "$ISSUES_DIR/14.md" "## Goal

Build reliable async processing with Redis queues.

## Tasks

- [ ] Redis queue setup
- [ ] Event structure: eventId, type, payload, retryCount, correlationId
- [ ] Publish events to queue

## Acceptance Criteria

- [ ] Events published with standard schema
- [ ] Correlation ID included in events
- [ ] Queue consumer can deserialize events

## Depends on

- Phase 10, Phase 13

## References

- \`project.md\` — Phase 14"

write_body "$ISSUES_DIR/15.md" "## Goal

Implement background workers that consume messages with retry and graceful shutdown.

## Tasks

- [ ] Consumer worker consumes messages
- [ ] Retry failures with backoff
- [ ] Move persistent failures to DLQ
- [ ] Graceful shutdown: stop consuming → finish in-flight → ack/commit → shutdown

## Acceptance Criteria

- [ ] Workers process events reliably
- [ ] Failed messages retried before DLQ
- [ ] Graceful shutdown completes in-flight jobs

## Depends on

- Phase 14

## References

- \`project.md\` — Phase 15"

write_body "$ISSUES_DIR/16.md" "## Goal

Handle failed messages with dead letter queue and manual reprocessing.

## Tasks

- [ ] Retries with DLQ fallback
- [ ] GET /api/v1/internal/dlq
- [ ] POST /api/v1/internal/dlq/{id}/reprocess
- [ ] DELETE /api/v1/internal/dlq/{id}
- [ ] Manual DLQ cleanup policy

## Acceptance Criteria

- [ ] Failed messages land in DLQ
- [ ] Reprocess and delete endpoints working

## Depends on

- Phase 15

## References

- \`project.md\` — Phase 16"

write_body "$ISSUES_DIR/17.md" "## Goal

Avoid duplicate processing when workers retry messages.

## Tasks

- [ ] Use processed_events table
- [ ] Verify event not already processed before handling

## Acceptance Criteria

- [ ] Duplicate events are skipped safely
- [ ] Retries do not cause duplicate side effects

## Depends on

- Phase 15

## References

- \`project.md\` — Phase 17"

write_body "$ISSUES_DIR/18.md" "## Goal

Guarantee reliable consistency between database writes and queue publishing.

## Tasks

- [ ] Save business data and outbox event in same transaction
- [ ] Commit transaction
- [ ] Publisher worker reads outbox and sends events to queue

## Acceptance Criteria

- [ ] No message loss between DB commit and queue publish
- [ ] Outbox events published after commit

## Depends on

- Phase 5, Phase 14

## References

- \`project.md\` — Phase 18"

write_body "$ISSUES_DIR/19.md" "## Goal

Deliver async report generation for business insights.

## Tasks

- [ ] Sales summary report
- [ ] Top products report
- [ ] Inventory report

## Acceptance Criteria

- [ ] Reports generated asynchronously
- [ ] Report endpoints or jobs return expected aggregates

## Depends on

- Phase 13

## References

- \`project.md\` — Phase 19"

write_body "$ISSUES_DIR/20.md" "## Goal

Track who changed what and when across core entities without breaking business flow.

## Tasks

- [ ] Audit CREATE / UPDATE / DELETE for customers, products, inventory, users, orders
- [ ] Capture performed_by, timestamp, correlation_id, old_payload, new_payload
- [ ] Audit never breaks business flow
- [ ] Audit log retention: 1 year

## Acceptance Criteria

- [ ] Audit records created for scoped entities
- [ ] Authenticated user and correlation ID included
- [ ] Audit failures do not roll back business transactions

## Depends on

- Phase 9

## References

- \`project.md\` — Phase 20"

write_body "$ISSUES_DIR/21.md" "## Goal

Expose read-heavy queries via GraphQL while keeping REST for writes.

## Tasks

- [ ] GraphQL queries: customers, products, orders, reports
- [ ] GraphQL mutations: createCustomer, createOrder
- [ ] REST remains primary for transactional writes

## Acceptance Criteria

- [ ] GraphQL schema covers read use cases
- [ ] Mutations work for defined write paths
- [ ] REST write endpoints unchanged

## Depends on

- Phase 3, Phase 4, Phase 5

## References

- \`project.md\` — Phase 21"

write_body "$ISSUES_DIR/22.md" "## Goal

Integrate AI assistants into business workflows via tool-calling, never direct DB writes.

## Tasks

- [ ] Finance assistant: summarize sales, explain revenue
- [ ] Inventory assistant: detect low stock
- [ ] Audit assistant: explain changes
- [ ] AI only calls services/tools
- [ ] Explore RAG, embeddings, vector search, agent orchestration

## Acceptance Criteria

- [ ] AI endpoints/tools return useful business insights
- [ ] No direct database writes from AI layer
- [ ] Tool calls reuse existing services

## Depends on

- Phase 19, Phase 20

## References

- \`project.md\` — Phase 22"

write_body "$ISSUES_DIR/23.md" "## Goal

Validate performance, bottlenecks, and concurrency behavior under load.

## Tasks

- [ ] Customer listing: 100 concurrent users on GET /api/v1/customers
- [ ] Order creation: 50 concurrent users; validate no negative stock, no duplicate orders, no deadlocks
- [ ] Queue stress test with thousands of async events
- [ ] Analyze p95/p99 latency, EXPLAIN ANALYZE, N+1 queries, connection pool saturation

## Acceptance Criteria

- [ ] JMeter scenarios documented and repeatable
- [ ] Critical paths meet defined concurrency integrity checks
- [ ] Performance findings documented with remediation notes

## Depends on

- Phase 5, Phase 18

## References

- \`project.md\` — Phase 23"

write_body "$ISSUES_DIR/24.md" "## Goal

Document key architecture decisions as ADRs for future reference.

## Tasks

- [ ] ADR: Why monolith first?
- [ ] ADR: Why Redis?
- [ ] ADR: Why GraphQL + REST?
- [ ] ADR: Why pessimistic locking?
- [ ] ADR: Why outbox pattern?

## Acceptance Criteria

- [ ] ADRs stored in repo
- [ ] Each ADR includes context, decision, and consequences

## Depends on

Ongoing — add/update as decisions are made.

## References

- \`project.md\` — ADRs"

write_body "$ISSUES_DIR/25.md" "## Goal

Provide operational documentation for running and recovering the system.

## Tasks

- [ ] Architecture overview
- [ ] Sync flow documentation
- [ ] Async flow documentation
- [ ] Retry flow documentation
- [ ] Local setup guide
- [ ] Recovery guides

## Acceptance Criteria

- [ ] Docs cover setup, core flows, and failure recovery
- [ ] Runbooks are actionable for common incidents

## Depends on

- Phase 23

## References

- \`project.md\` — Documentation & Runbooks"

echo "Creating epic issue..."
if [[ -n "${EPIC_NUMBER:-}" ]]; then
  EPIC_URL="https://github.com/$REPO/issues/$EPIC_NUMBER"
  EPIC_ID=$(get_issue_id "$EPIC_NUMBER")
  echo "Using existing epic: #$EPIC_NUMBER ($EPIC_URL)"
else
  EPIC_URL=$(gh issue create --repo "$REPO" --title "[Epic] Mini ERP — Backend Engineering Roadmap" --body-file "$ISSUES_DIR/epic.md" --label "epic")
  EPIC_NUMBER=$(echo "$EPIC_URL" | grep -oE '[0-9]+$')
  EPIC_ID=$(get_issue_id "$EPIC_NUMBER")
  echo "Epic: #$EPIC_NUMBER ($EPIC_URL)"
fi

declare -a SUB_NUMBERS=()
declare -a SUB_TITLES=()

create_sub_issue() {
  local num="$1" title="$2" milestone="$3" labels_csv="$4"
  local body_file="$ISSUES_DIR/$(printf '%02d' "$num").md"

  local -a args=(issue create --repo "$REPO" --title "$title" --body-file "$body_file" --milestone "$milestone" --label "phase")
  IFS=',' read -ra labels <<< "$labels_csv"
  for lbl in "${labels[@]}"; do
    [[ -n "$lbl" ]] && args+=(--label "$lbl")
  done

  local url issue_number
  url=$(gh "${args[@]}")
  issue_number=$(echo "$url" | grep -oE '[0-9]+$')
  SUB_NUMBERS+=("$issue_number")
  SUB_TITLES+=("$title")
  link_sub_issue "$EPIC_ID" "$(get_issue_id "$issue_number")"
  echo "  #$issue_number — $title"
}

echo "Creating sub-issues..."
create_sub_issue 1 "[Phase 1] Foundation — Spring Boot bootstrap & standards" "M1 — Foundation" "type:infra,good first issue"
create_sub_issue 2 "[Phase 2] Database & Migrations — Flyway schema" "M1 — Foundation" "type:infra"
create_sub_issue 3 "[Phase 3] Customers — CRUD API" "M2 — Core Domain" "type:feature,good first issue"
create_sub_issue 4 "[Phase 4] Products & Inventory — stock management" "M2 — Core Domain" "type:feature"
create_sub_issue 5 "[Phase 5] Orders — transactional core with pessimistic locking" "M2 — Core Domain" "type:feature"
create_sub_issue 6 "[Phase 6] Testing — unit, integration & concurrency tests" "M3 — Quality & Ops" "type:quality"
create_sub_issue 7 "[Phase 7] Logging — structured logs & event tracking" "M3 — Quality & Ops" "type:quality"
create_sub_issue 8 "[Phase 8] Observability — metrics & correlation IDs" "M3 — Quality & Ops" "type:quality"
create_sub_issue 9 "[Phase 9] Authentication & Authorization — JWT + RBAC" "M3 — Quality & Ops" "type:security"
create_sub_issue 10 "[Phase 10] Docker — local reproducible environment" "M3 — Quality & Ops" "type:infra"
create_sub_issue 11 "[Phase 11] Kubernetes — deployment basics" "M3 — Quality & Ops" "type:infra"
create_sub_issue 12 "[Phase 12] Code Quality & CI — lint, format, GitHub Actions" "M3 — Quality & Ops" "type:quality"
create_sub_issue 13 "[Phase 13] Async Operations — decouple heavy processing" "M4 — Async Platform" "type:async"
create_sub_issue 14 "[Phase 14] Queues — Redis message infrastructure" "M4 — Async Platform" "type:async"
create_sub_issue 15 "[Phase 15] Workers — consume, retry, ack" "M4 — Async Platform" "type:async"
create_sub_issue 16 "[Phase 16] DLQ & Reprocessing" "M4 — Async Platform" "type:async"
create_sub_issue 17 "[Phase 17] Idempotency — processed_events table" "M4 — Async Platform" "type:async"
create_sub_issue 18 "[Phase 18] Outbox Pattern — DB + queue consistency" "M4 — Async Platform" "type:async"
create_sub_issue 19 "[Phase 19] Reports — sales, top products, inventory" "M5 — Advanced Features" "type:feature"
create_sub_issue 20 "[Phase 20] Audit System — change tracking" "M5 — Advanced Features" "type:feature"
create_sub_issue 21 "[Phase 21] GraphQL — read-heavy queries" "M5 — Advanced Features" "type:feature"
create_sub_issue 22 "[Phase 22] AI Assistant — tool-calling integration" "M5 — Advanced Features" "type:feature"
create_sub_issue 23 "[Phase 23] Load Testing & Performance — JMeter scenarios" "M5 — Advanced Features" "type:quality"
create_sub_issue 24 "[Cross-cutting] ADRs — document architecture decisions" "M6 — Engineering Maturity" "type:docs"
create_sub_issue 25 "[Cross-cutting] Documentation & Runbooks" "M6 — Engineering Maturity" "type:docs"

echo "Updating epic with sub-issue links..."
EPIC_BODY_FILE="$ISSUES_DIR/epic-final.md"
{
  head -n 68 "$ISSUES_DIR/epic.md"
  cat <<EOF

### M1 — Foundation
- [ ] #${SUB_NUMBERS[0]} — ${SUB_TITLES[0]}
- [ ] #${SUB_NUMBERS[1]} — ${SUB_TITLES[1]}

### M2 — Core Domain
- [ ] #${SUB_NUMBERS[2]} — ${SUB_TITLES[2]}
- [ ] #${SUB_NUMBERS[3]} — ${SUB_TITLES[3]}
- [ ] #${SUB_NUMBERS[4]} — ${SUB_TITLES[4]}

### M3 — Quality & Ops
- [ ] #${SUB_NUMBERS[5]} — ${SUB_TITLES[5]}
- [ ] #${SUB_NUMBERS[6]} — ${SUB_TITLES[6]}
- [ ] #${SUB_NUMBERS[7]} — ${SUB_TITLES[7]}
- [ ] #${SUB_NUMBERS[8]} — ${SUB_TITLES[8]}
- [ ] #${SUB_NUMBERS[9]} — ${SUB_TITLES[9]}
- [ ] #${SUB_NUMBERS[10]} — ${SUB_TITLES[10]}
- [ ] #${SUB_NUMBERS[11]} — ${SUB_TITLES[11]}

### M4 — Async Platform
- [ ] #${SUB_NUMBERS[12]} — ${SUB_TITLES[12]}
- [ ] #${SUB_NUMBERS[13]} — ${SUB_TITLES[13]}
- [ ] #${SUB_NUMBERS[14]} — ${SUB_TITLES[14]}
- [ ] #${SUB_NUMBERS[15]} — ${SUB_TITLES[15]}
- [ ] #${SUB_NUMBERS[16]} — ${SUB_TITLES[16]}
- [ ] #${SUB_NUMBERS[17]} — ${SUB_TITLES[17]}

### M5 — Advanced Features
- [ ] #${SUB_NUMBERS[18]} — ${SUB_TITLES[18]}
- [ ] #${SUB_NUMBERS[19]} — ${SUB_TITLES[19]}
- [ ] #${SUB_NUMBERS[20]} — ${SUB_TITLES[20]}
- [ ] #${SUB_NUMBERS[21]} — ${SUB_TITLES[21]}
- [ ] #${SUB_NUMBERS[22]} — ${SUB_TITLES[22]}

### M6 — Engineering Maturity
- [ ] #${SUB_NUMBERS[23]} — ${SUB_TITLES[23]}
- [ ] #${SUB_NUMBERS[24]} — ${SUB_TITLES[24]}

EOF
  tail -n +70 "$ISSUES_DIR/epic.md"
} > "$EPIC_BODY_FILE"

gh issue edit "$EPIC_NUMBER" --repo "$REPO" --body-file "$EPIC_BODY_FILE"

LINE_COUNT=$(wc -l < "$EPIC_BODY_FILE")
echo ""
echo "Done! Epic body: ${LINE_COUNT} lines"
echo "Epic: $EPIC_URL"
for i in "${!SUB_NUMBERS[@]}"; do
  echo "  #${SUB_NUMBERS[$i]} — ${SUB_TITLES[$i]}"
done
