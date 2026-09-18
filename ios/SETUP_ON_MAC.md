# Matrix Test su macOS / Xcode

## Cosa serve

- Mac con l’ultima versione compatibile di Xcode.
- Un Apple ID: per una prova privata non serve pubblicare su App Store.
- Due iPhone collegabili al Mac almeno per la prima installazione.
- Il progetto Supabase già configurato con le due migrazioni e le Edge Functions.

## 1. Apri il progetto Xcode

Non sono necessari Homebrew o XcodeGen. Apri direttamente:

```bash
open MatrixTest.xcodeproj
```

## 2. Inserisci i dati Supabase

Apri `Sources/MatrixTestConfig.swift` e sostituisci soltanto:

- `YOUR-PROJECT` con l’host del progetto Supabase;
- `YOUR-ANON-OR-PUBLISHABLE-KEY` con la chiave publishable/anon.

Non inserire mai `service_role`, password, segreti bootstrap o chiavi private nel progetto iOS.

## 3. Firma e installa

In Xcode:

1. Seleziona il target `MatrixTest`.
2. In **Signing & Capabilities**, scegli il tuo Team Apple ID.
3. Collega il primo iPhone, selezionalo come destinazione e premi Run.
4. Ripeti con il secondo iPhone.

La build Debug installata con Apple ID gratuito è per uso personale e va rifirmata periodicamente. Non viene pubblicata su App Store.

## 4. Primo test

1. Avvia la build Debug sul primo iPhone.
2. Usa **INIZIALIZZA GHOST / BLACK** e il segreto monouso configurato su Supabase; imposta una password lunga e un codice locale.
3. Avvia il secondo iPhone e registra un account diverso.
4. Dal secondo iPhone cerca `E1`: la richiesta deve essere rifiutata.
5. Da Ghost cerca il codice del secondo account e invia una richiesta.
6. Controlla il pannello Admin di Ghost: deve vedere conteggi e stato account, non messaggi.

## Non ancora abilitato

La chat è volutamente non attiva in questa build finché non integriamo un protocollo E2EE auditato. Il backend accetta solo buste cifrate, ma non bisogna presentare come “E2E completa” un’implementazione che non ha ancora il ratchet/protocollo verificato.
