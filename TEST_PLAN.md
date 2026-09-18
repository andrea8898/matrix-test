# Piano di verifica Matrix Test

## Backend

- `001_matrix_test.sql` termina senza errori.
- `002_matrix_api.sql` termina senza errori e può essere rieseguito.
- `Black`, `black` e varianti maiuscole/minuscole non possono coesistere.
- Il primo bootstrap crea soltanto `Ghost` / `Black`, assegnato a `E1`.
- Un secondo bootstrap fallisce.

## Due iPhone

- Ghost può accedere, vedere il pannello Admin e disabilitare un account.
- L’account normale non può inviare una richiesta a `E1`.
- L’account normale può cercare un codice `E…` valido.
- Un codice locale errato elimina token e chiave del dispositivo; l’account backend non viene cancellato automaticamente.
- Un account disabilitato non può più effettuare accesso o heartbeat.

## Prima di coinvolgere altri tester

- Aggiungere rate limiting per registrazione e login.
- Aggiungere test automatizzati lato Edge Functions.
- Integrare un protocollo di messaggistica E2EE sottoposto ad audit.
- Completare flusso richieste/chat e prova su rete mobile, non solo Wi‑Fi.
