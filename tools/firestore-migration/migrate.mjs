#!/usr/bin/env node
// Firestore -> Supabase migration CLI. See README.md.
import { readFile, writeFile } from 'node:fs/promises';
import { parseArgs } from 'node:util';

import { transform } from './transform.mjs';

const USAGE = `Usage:
  node migrate.mjs extract --service-account <key.json> --out <dump.json>
  node migrate.mjs plan <dump.json> --timezone <IANA zone> [--organization <name>] [--out <plan.json>]
  node migrate.mjs load <dump.json> --timezone <IANA zone> --database-url <url>
                        [--supabase-url <url> --service-key <key>] [--organization <name>] [--allow-existing]

  --service-key and --database-url can also come from SUPABASE_SERVICE_ROLE_KEY and DATABASE_URL.`;

const { positionals, values } = parseArgs({
  allowPositionals: true,
  options: {
    'service-account': { type: 'string' },
    out: { type: 'string' },
    timezone: { type: 'string' },
    organization: { type: 'string' },
    'database-url': { type: 'string', default: process.env.DATABASE_URL },
    'supabase-url': { type: 'string' },
    'service-key': { type: 'string', default: process.env.SUPABASE_SERVICE_ROLE_KEY },
    'allow-existing': { type: 'boolean', default: false },
  },
});

const [command, dumpPath] = positionals;

async function plan() {
  if (!dumpPath || !values.timezone) throw new Error(USAGE);
  const dump = JSON.parse(await readFile(dumpPath, 'utf8'));
  return transform(dump, { timeZone: values.timezone, organization: values.organization });
}

function report(result) {
  console.log('Rows to migrate:');
  for (const [table, count] of Object.entries(result.stats)) console.log(`  ${table.padEnd(22)} ${count}`);
  console.log(`\n${result.warnings.length} warning(s)${result.warnings.length ? ':' : ''}`);
  for (const warning of result.warnings) console.log(`  - ${warning}`);
}

try {
  switch (command) {
    case 'extract': {
      if (!values['service-account'] || !values.out) throw new Error(USAGE);
      const { extract } = await import('./extract.mjs');
      await writeFile(values.out, JSON.stringify(await extract({ serviceAccount: values['service-account'] }), null, 2));
      console.log(`Wrote ${values.out}`);
      break;
    }
    case 'plan': {
      const result = await plan();
      report(result);
      if (values.out) await writeFile(values.out, JSON.stringify(result, null, 2));
      break;
    }
    case 'load': {
      if (!values['database-url']) throw new Error(USAGE);
      const result = await plan();
      report(result);
      console.log('\nLoading...');
      const { load } = await import('./load.mjs');
      await load(result, {
        databaseUrl: values['database-url'],
        supabaseUrl: values['supabase-url'],
        serviceKey: values['service-key'],
        allowExisting: values['allow-existing'],
      });
      console.log('\nDone.');
      break;
    }
    default:
      throw new Error(USAGE);
  }
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
