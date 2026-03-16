---
name: git-clean-push
description: Sauberer Commit und Push mit Validierung
disable-model-invocation: true
---
Fuehre einen sauberen Git Commit und Push durch. Gehe dabei diese Schritte durch:

## 1. Status pruefen
- `git status` ausfuehren und dem User zeigen
- Pruefen ob untracked Files existieren die committet werden sollten
- Pruefen ob es unstaged Changes gibt
- Wenn nichts zu committen ist: User informieren und abbrechen

## 2. Qualitaetschecks (nur geaenderte Dateien)
- Zuerst die Liste der geaenderten Dateien ermitteln: `git diff --name-only --cached` (staged) und `git diff --name-only` (unstaged)
- Falls `package.json` existiert und ein lint-Script vorhanden ist: Lint nur auf die geaenderten Dateien ausfuehren (z.B. `npx eslint <geaenderte-files>` oder `npx prettier --check <geaenderte-files>`)
- Falls `package.json` existiert: `npm run typecheck` oder `npx tsc --noEmit` ausfuehren (Typecheck muss immer auf das ganze Projekt laufen)
- Falls `pyproject.toml` existiert: `ruff check <geaenderte-files>` ausfuehren
- Bei Fehlern: dem User zeigen und fragen ob trotzdem committed werden soll
- WICHTIG: Nicht automatisch fixen, nur pruefen und berichten
- WICHTIG: Niemals `npm run lint` oder `ruff check .` auf das gesamte Projekt ausfuehren - immer nur die geaenderten Dateien pruefen

## 3. Staging
- Dem User zeigen welche Files staged werden
- Keine .env, credentials, oder Secrets stagen - warnen falls vorhanden
- Alle relevanten geaenderten und neuen Files stagen
- Falls der User $ARGUMENTS angegeben hat, diese als Filter fuer die Files verwenden

## 4. Commit
- `git log --oneline -5` anschauen um den Commit-Style des Projekts zu verstehen
- Commit-Message vorschlagen die zum Stil passt (Conventional Commits falls genutzt)
- Commit-Message dem User zeigen und per AskUserQuestion bestaetigen lassen
- Commit ausfuehren

## 5. Push
- Pruefen ob ein Remote konfiguriert ist
- Pruefen ob der Branch einen Upstream hat, falls nicht `git push -u origin <branch>` verwenden
- `git push` ausfuehren
- Bei Fehlern (z.B. rejected weil remote weiter ist): dem User Optionen zeigen (pull --rebase, force push, abbrechen)

## 6. Abschluss
- Finalen `git status` zeigen um zu bestaetigen dass das Verzeichnis clean ist
- Kurze Zusammenfassung: Branch, Commit-Hash, was gepusht wurde
