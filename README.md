# Matrix Test — prova privata per due iPhone

Questa cartella è separata da `work/matrix-ios` e non modifica il progetto originale.

## Risultato previsto

- Due iPhone installano la build direttamente da Xcode.
- I dispositivi si collegano allo stesso servizio demo durante il test.
- Account, ricerca per codice `E…`, richieste e presenza usano il backend.
- La prova non viene pubblicata su App Store e non richiede un servizio a pagamento.

## Analisi e scelta tecnica

| Area | Scelta per test | Motivo |
| --- | --- | --- |
| App | SwiftUI nativa | Accesso a Portachiavi, Face ID e comportamento iPhone affidabile. |
| Installazione | Xcode su Mac + Apple ID gratuito | Non richiede App Store né abbonamento Apple Developer per una prova privata. |
| Backend | Supabase Free + Edge Functions | Database e API HTTPS senza mantenere un server. |
| Comunicazione | Polling HTTPS per la prova | Più semplice da testare con un’autenticazione username senza email. |
| Crittografia | Da integrare con protocollo E2EE sottoposto ad audit | Una demo non deve inventare un protocollo e chiamarlo sicuro. |

## Limiti da non ignorare

1. Un Mac con Xcode è indispensabile per compilare e installare l'app su iPhone. Windows non può produrre una build iOS firmata.
2. L'Apple ID gratuito permette l'installazione diretta, ma le build di sviluppo scadono periodicamente e richiedono nuova firma da Xcode. Non pubblica nulla.
3. Supabase Free richiede un account Supabase, ma non richiede carta per la prova normale. Il progetto può andare in pausa se inutilizzato.
4. Il backend accetta soltanto buste `ciphertext` e metadati crittografici. La chat resta disattivata finché non sarà integrato e verificato un protocollo E2EE auditato.
5. L'ID progressivo deve essere attribuito dal database. Il client non può scegliere `E1` o un altro codice.

## Passi per una prova reale

1. Installa Xcode su un Mac e collega entrambi gli iPhone via cavo almeno al primo avvio.
2. Crea un progetto Supabase gratuito e segui [DEPLOYMENT.md](supabase/DEPLOYMENT.md).
3. Sul Mac apri direttamente `ios/MatrixTest.xcodeproj` con Xcode 15.2: non servono Homebrew o XcodeGen.
4. Aggiorna `ios/Sources/MatrixTestConfig.swift` con URL e chiave publishable/anon; la chiave `service_role` non deve mai entrare nell'app.
5. Apri il progetto in Xcode, seleziona il tuo Team di firma e installa la build sui due dispositivi.
6. Crea `Ghost` / `Black` una sola volta dalla build Debug, poi registra un secondo account e verifica ricerca e richieste.

La procedura completa per il Mac è in [ios/SETUP_ON_MAC.md](ios/SETUP_ON_MAC.md); le verifiche richieste sono in [TEST_PLAN.md](TEST_PLAN.md).

## Cosa mi serve per completare il collegamento reale

- URL del progetto Supabase.
- Chiave anon/publishable di Supabase (non la chiave `service_role`).
- Accesso a un Mac con Xcode 15.2 per compilare e firmare la prova.

Non condividere password, codici di sblocco, chiavi private o chiavi `service_role`.
