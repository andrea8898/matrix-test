# Deploy backend Matrix Test

## Prerequisiti

- Account Supabase e progetto vuoto dedicato alla prova.
- Supabase CLI su un computer che possa accedere al progetto.
- Non usare il progetto originale Matrix per questi comandi.

## 1. Database

Nel SQL Editor esegui, nell'ordine:

1. `001_matrix_test.sql`
2. `002_matrix_api.sql`

Verifica che RLS resti attivo e che le tabelle non abbiano policy aperte al ruolo anonimo.

## 2. Segreto di inizializzazione fondatore

Scegli un segreto monouso diverso dal codice locale e dalla password dell'account Ghost. Salvalo soltanto nel backend:

```powershell
supabase secrets set FOUNDER_BOOTSTRAP_SECRET="un-segreto-lungo-monomonouso"
```

Non inserire `07-10` in un file, nel codice iOS o nella chat. Se `07-10` è un requisito di design, usalo solo come etichetta visuale: è troppo breve per proteggere l'account amministratore.

## 3. Deploy Edge Functions

Dalla cartella `supabase`:

```powershell
supabase login
supabase link --project-ref IL_TUO_PROJECT_REF
supabase functions deploy register
supabase functions deploy bootstrap-founder
supabase functions deploy login
supabase functions deploy directory-find
supabase functions deploy friend-request
supabase functions deploy friend-respond
supabase functions deploy presence-heartbeat
supabase functions deploy messages-send
supabase functions deploy messages-poll
supabase functions deploy admin-dashboard
supabase functions deploy admin-account-action
```

## 4. Inizializzazione Ghost / Black

La prima chiamata a `bootstrap-founder` crea l'unico account fondatore, con:

- nome visibile: `Ghost`
- username: `Black`
- identificativo pubblico assegnato dal database: `E1`

Per la prova, aggiungi nell'app una pagina di bootstrap temporanea oppure invia la chiamata da uno strumento locale protetto. Dopo la creazione, ruota o elimina `FOUNDER_BOOTSTRAP_SECRET` e non distribuire mai quella schermata nella build dei tester.

## Test minimo

1. Registra `Ghost` / `Black` tramite bootstrap.
2. Registra un secondo account tramite `register`.
3. Verifica che un secondo `Black` venga rifiutato anche se scritto `black`.
4. Verifica che l'utente normale non possa inviare richieste o messaggi a `E1`.
5. Verifica che il fondatore possa disabilitare il secondo account senza visualizzare ciphertext.
