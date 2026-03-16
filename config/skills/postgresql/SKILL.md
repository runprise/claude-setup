---
name: postgresql
description: PostgreSQL Performance, Maintenance und Query-Optimierung
---
When working with PostgreSQL databases:

## Query-Analyse & Optimierung

### EXPLAIN ANALYZE Workflow
- Immer `EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)` fuer echte Laufzeiten
- Auf Seq Scans bei grossen Tabellen achten - oft fehlt ein Index
- `rows=` Schaetzung vs. `actual rows=` vergleichen - grosse Abweichungen deuten auf veraltete Statistiken
- `Buffers: shared hit` vs `shared read` - niedrige Hit-Rate = zu wenig `shared_buffers` oder fehlender Index
- Bei `Sort Method: external merge` → `work_mem` erhoehen

### Slow Query Diagnose
```sql
-- Top 10 langsamste Queries (pg_stat_statements muss aktiv sein)
SELECT query, calls, mean_exec_time::numeric(10,2) as avg_ms,
       total_exec_time::numeric(10,2) as total_ms,
       rows,
       100.0 * shared_blks_hit / NULLIF(shared_blks_hit + shared_blks_read, 0) as cache_hit_pct
FROM pg_stat_statements
ORDER BY mean_exec_time DESC LIMIT 10;
```

### Query-Optimierung Patterns
- JOINs: Immer auf indexierte Spalten joinen
- WHERE: Funktionen auf Spalten vermeiden (`WHERE LOWER(email)` verhindert Index-Nutzung → funktionaler Index)
- IN vs EXISTS: `EXISTS` bei korrelierten Subqueries bevorzugen
- LIKE: `LIKE 'prefix%'` nutzt B-tree Index, `LIKE '%suffix'` nicht → `pg_trgm` Extension + GIN Index
- Pagination: `OFFSET` vermeidet bei grossen Offsets → Keyset Pagination (`WHERE id > last_id LIMIT n`)
- SELECT: Nur benoetigte Spalten, nie `SELECT *` in Produktion
- CTEs: Ab PG12 werden CTEs automatisch inlined, aber `MATERIALIZED` erzwingen wenn noetig

## Index-Strategie

### Index-Typen
- **B-tree** (Standard): Gleichheit, Bereich, Sortierung - fuer die meisten Faelle
- **GIN**: Arrays, JSONB, Volltext, `pg_trgm` - fuer Containment-Queries
- **GiST**: Geometrie, Bereiche, Volltext - fuer Ueberlappungs-Queries
- **BRIN**: Sehr grosse Tabellen mit natuerlicher Sortierung (z.B. Zeitreihen nach created_at)
- **Hash**: Nur fuer reine Gleichheits-Queries (selten besser als B-tree)

### Index Best Practices
- Composite Indexes: Selektivste Spalte zuerst, Reihenfolge der WHERE-Klausel folgen
- Partial Indexes: `WHERE status = 'active'` wenn nur Teilmenge abgefragt wird
- Covering Indexes: `INCLUDE (spalte)` fuer Index-Only Scans
- Funktionale Indexes: `CREATE INDEX ON users (LOWER(email))` fuer Case-Insensitive Suche
- NICHT ueber-indexieren: Jeder Index kostet Write-Performance und Speicher

### Unused Indexes finden
```sql
SELECT schemaname, relname, indexrelname, idx_scan,
       pg_size_pretty(pg_relation_size(indexrelid)) as idx_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;
```

### Missing Indexes erkennen
```sql
SELECT relname, seq_scan, idx_scan,
       seq_scan - idx_scan as too_many_seq,
       pg_size_pretty(pg_relation_size(relid)) as size
FROM pg_stat_user_tables
WHERE seq_scan > idx_scan AND pg_relation_size(relid) > 100000
ORDER BY seq_scan - idx_scan DESC LIMIT 20;
```

## Maintenance

### VACUUM & ANALYZE
- `VACUUM ANALYZE tabelle` - Standard-Maintenance, nicht-blockierend
- `VACUUM FULL tabelle` - Gibt Disk frei, SPERRT die Tabelle - nur im Wartungsfenster
- `ANALYZE tabelle` - Statistiken aktualisieren fuer den Query Planner
- `VACUUM (VERBOSE, ANALYZE) tabelle` - Mit Fortschrittsanzeige
- Nach grossen DELETE/UPDATE Operationen immer VACUUM ausfuehren

### Autovacuum Tuning
```sql
-- Fuer High-Churn Tabellen aggressiveres Autovacuum
ALTER TABLE high_churn_table SET (
    autovacuum_vacuum_scale_factor = 0.05,    -- Standard: 0.2
    autovacuum_analyze_scale_factor = 0.02,   -- Standard: 0.1
    autovacuum_vacuum_cost_delay = 10         -- Standard: 20ms
);
```

### Table Bloat pruefen
```sql
SELECT schemaname, tablename,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
       pg_size_pretty(pg_table_size(schemaname||'.'||tablename)) as table_size,
       pg_size_pretty(pg_indexes_size(schemaname||'.'||tablename)) as index_size,
       n_dead_tup, n_live_tup,
       ROUND(n_dead_tup::numeric / NULLIF(n_live_tup, 0) * 100, 2) as dead_pct
FROM pg_stat_user_tables
JOIN pg_tables USING (schemaname, tablename)
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### REINDEX
- `REINDEX INDEX CONCURRENTLY idx_name` - Online ohne Lock
- `REINDEX TABLE CONCURRENTLY tabelle` - Alle Indexes der Tabelle neu bauen
- Noetig bei Index-Bloat oder nach vielen Updates

## Konfigurations-Tuning

### Speicher (Hauptstellschrauben)
- `shared_buffers`: 25% des RAM (z.B. 4GB bei 16GB RAM)
- `effective_cache_size`: 75% des RAM (Hinweis fuer den Planner)
- `work_mem`: 64-256MB je nach Query-Komplexitaet (Vorsicht: pro Sort-Operation!)
- `maintenance_work_mem`: 512MB-1GB (fuer VACUUM, CREATE INDEX)

### WAL & Checkpoints
- `wal_buffers`: 64MB
- `checkpoint_completion_target`: 0.9
- `max_wal_size`: 2-4GB

### Connection Management
- `max_connections`: Niedrig halten (100-200), Connection Pooler davor (PgBouncer)
- Jede Connection = ~10MB RAM - 1000 Connections = 10GB RAM nur fuer Connections

### Logging fuer Diagnose
```sql
-- In postgresql.conf oder per SET:
SET log_min_duration_statement = 500;  -- Queries >500ms loggen
SET log_lock_waits = on;               -- Lock-Waits loggen
SET log_temp_files = 0;                -- Temp-File Nutzung loggen
```

## pg_stat_statements Setup
```ini
# postgresql.conf - MUSS aktiviert sein fuer Query-Analyse
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.max = 10000
pg_stat_statements.track = all
```
```sql
-- Extension aktivieren
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
-- Statistiken zuruecksetzen (z.B. nach Config-Aenderung)
SELECT pg_stat_statements_reset();
```

## Monitoring Essentials
```sql
-- Aktive Queries und Locks
SELECT pid, now() - pg_stat_activity.query_start as duration,
       query, state, wait_event_type, wait_event
FROM pg_stat_activity
WHERE state != 'idle' AND query NOT LIKE '%pg_stat%'
ORDER BY duration DESC;

-- Cache Hit Ratio (sollte >99% sein)
SELECT sum(heap_blks_hit) / NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0) as ratio
FROM pg_statio_user_tables;

-- Index Hit Ratio (sollte >95% sein)
SELECT sum(idx_blks_hit) / NULLIF(sum(idx_blks_hit) + sum(idx_blks_read), 0) as ratio
FROM pg_statio_user_indexes;

-- Connections pro State
SELECT state, count(*) FROM pg_stat_activity GROUP BY state;
```
