#!/usr/bin/env node
// Cobertura em código NOVO (doc 14): % das linhas adicionadas no diff que a
// suíte executa. Gate repo-inteiro pune legado e esconde PR sem teste na média;
// este mede só o que o PR introduz.
//
// Uso:  node scripts/diff-coverage.mjs [base-ref]     (default: origin/master)
// Pré:  suíte já rodada com cobertura → coverage/coverage-final.json (istanbul,
//       formato que Vitest e Jest emitem com coverageReporters: ['json']).
// Gate: exit 1 se % < DIFF_COVERAGE_MIN (default 80). Piso é piso — nunca
//       reduzir (doc 01, 2b).
//
// Limitações deliberadas (documentadas > escondidas — doc 04):
// - Arquivo novo sem NENHUM teste não aparece no report → todas as linhas
//   adicionadas dele contam como não cobertas. É o comportamento desejado.
// - Linha adicionada que não é statement (import de tipo, comentário, chave
//   solta) fica fora do denominador quando o arquivo está no report.
import { execSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { relative } from 'node:path';

const BASE = process.argv[2] ?? 'origin/master';
const MIN = Number(process.env.DIFF_COVERAGE_MIN ?? 80);
const REPORT = 'coverage/coverage-final.json'; // ⟨ajuste ao output do seu runner⟩
const SRC = /\.(ts|tsx|js|jsx|mjs)$/; // ⟨extensões de código de app⟩
const EXCLUDE = /(^|\/)(tests?|__tests__|__mocks__)\/|\.(test|spec)\./; // teste não entra no denominador

// --- linhas adicionadas por arquivo, do diff unificado ---
const diff = execSync(
    `git diff --unified=0 --diff-filter=ACM ${BASE}...HEAD`,
    { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 },
);
const added = new Map(); // path → Set<linha>
let file = null;
for (const line of diff.split('\n')) {
    const f = line.match(/^\+\+\+ b\/(.+)$/);
    if (f) {
        file = SRC.test(f[1]) && !EXCLUDE.test(f[1]) ? f[1] : null;
        if (file && !added.has(file)) added.set(file, new Set());
        continue;
    }
    const h = file && line.match(/^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@/);
    if (h) {
        const start = Number(h[1]);
        const count = h[2] === undefined ? 1 : Number(h[2]);
        for (let i = 0; i < count; i++) added.get(file).add(start + i);
    }
}

if (added.size === 0) {
    console.log(`diff-coverage: nenhum arquivo de código alterado vs ${BASE} — ok`);
    process.exit(0);
}

// --- cobertura por linha, do report istanbul (chaves são caminhos absolutos) ---
const report = JSON.parse(readFileSync(REPORT, 'utf8'));
const byRel = new Map();
for (const [abs, data] of Object.entries(report)) {
    byRel.set(relative(process.cwd(), abs), data);
}

let covered = 0;
let total = 0;
const rows = [];
for (const [path, lines] of added) {
    const data = byRel.get(path);
    let c = 0;
    let t = 0;
    if (!data) {
        t = lines.size; // fora do report = nada executa este arquivo
    } else {
        const hits = new Map(); // linha → soma de hits dos statements que começam nela
        for (const [id, loc] of Object.entries(data.statementMap)) {
            const ln = loc.start.line;
            hits.set(ln, (hits.get(ln) ?? 0) + (data.s[id] ?? 0));
        }
        for (const ln of lines) {
            if (!hits.has(ln)) continue; // linha não-executável
            t++;
            if (hits.get(ln) > 0) c++;
        }
    }
    covered += c;
    total += t;
    if (t > 0) rows.push(`  ${path}: ${c}/${t}${data ? '' : ' (sem teste algum)'}`);
}

const pct = total === 0 ? 100 : (covered / total) * 100;
console.log(`diff-coverage vs ${BASE}:`);
for (const r of rows) console.log(r);
console.log(`total: ${covered}/${total} linhas novas cobertas (${pct.toFixed(1)}% — piso ${MIN}%)`);
process.exit(pct >= MIN ? 0 : 1);
