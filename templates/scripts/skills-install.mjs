#!/usr/bin/env node
// Restaura as skills vendorizadas a partir do skills-lock.json (fonte da verdade)
// e as relinka em .claude/skills/ para o Claude Code descobri-las.
//
// Por que Node (e não shell): roda em qualquer lugar que o npm roda — inclusive
// Windows, onde `bash`/`ln -s` não existem por padrão. O linking usa symlink com
// fallback para cópia (Windows sem modo desenvolvedor não cria symlink).
//
// Dois passos, porque `skills experimental_install` restaura só o store canônico
// em .agents/skills/ — o lock não guarda o alvo por agente, então os symlinks que
// o Claude Code lê (.claude/skills/) são recriados aqui. Ambos os destinos são
// gitignorados (gerados); o que vai pro git é só o skills-lock.json + este script.
//
// Modos:
//   node scripts/skills-install.mjs               força a instalação (npm run skills:install)
//   node scripts/skills-install.mjs --if-missing  best-effort no postinstall: pula em CI,
//                                                  pula se já instaladas, e nunca quebra o npm i.

import { execSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const agentsSkills = path.join(repoRoot, ".agents", "skills");
const claudeSkills = path.join(repoRoot, ".claude", "skills");
const ifMissing = process.argv.includes("--if-missing");

function skillDirs(dir) {
  try {
    return fs.readdirSync(dir).filter((n) => fs.statSync(path.join(dir, n)).isDirectory());
  } catch {
    return [];
  }
}

// postinstall (--if-missing): não roda em CI/builds nem se as skills já existem.
if (ifMissing) {
  if (process.env.CI) process.exit(0);
  if (skillDirs(agentsSkills).length > 0) process.exit(0);
}

try {
  // 1. Restaura .agents/skills/ com as skills fixadas por hash no lock.
  execSync("npx --yes skills experimental_install", { cwd: repoRoot, stdio: "inherit" });

  // 2. Recria .claude/skills/ do zero (sem deixar link órfão de skill removida).
  fs.rmSync(claudeSkills, { recursive: true, force: true });
  fs.mkdirSync(claudeSkills, { recursive: true });

  // SKILLS_COPY=1 força cópia em vez de symlink (útil onde symlink não é confiável).
  const forceCopy = !!process.env.SKILLS_COPY;
  const names = skillDirs(agentsSkills);
  for (const name of names) {
    const link = path.join(claudeSkills, name);
    if (!forceCopy) {
      try {
        // Alvo relativo mantém o link portável entre máquinas.
        fs.symlinkSync(path.join("..", "..", ".agents", "skills", name), link, "dir");
        continue;
      } catch {
        // Sem permissão de symlink (ex.: Windows sem modo dev): cai pra cópia.
      }
    }
    fs.cpSync(path.join(agentsSkills, name), link, { recursive: true });
  }

  console.log(
    `Skills restauradas: ${names.length} em .agents/skills/ + ${names.length} em .claude/skills/`
  );
} catch (err) {
  if (ifMissing) {
    // best-effort: avisa, mas não derruba o `npm install`.
    console.warn(
      "[skills] não foi possível restaurar as skills automaticamente (offline?). " +
        "Rode `npm run skills:install` quando tiver rede."
    );
    process.exit(0);
  }
  throw err;
}
