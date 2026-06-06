import fs from 'node:fs';
import path from 'node:path';
import { DatabaseSync } from 'node:sqlite';

const root = process.cwd();
const dbPath = path.join(root, 'prisma', 'dev.db');
const migrationPath = path.join(
  root,
  'prisma',
  'migrations',
  '20260606000000_init',
  'migration.sql',
);

fs.mkdirSync(path.dirname(dbPath), { recursive: true });

if (fs.existsSync(dbPath)) {
  fs.rmSync(dbPath);
}

const sql = fs.readFileSync(migrationPath, 'utf8');
const db = new DatabaseSync(dbPath);
db.exec('PRAGMA foreign_keys = ON;');
db.exec(sql);
db.close();

console.log(`SQLite database migrated: ${dbPath}`);
