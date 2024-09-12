# Health Checks

## App

Der Endpoint **/healthz** kann für einen generellen Health-Check der Applikation getriggert werden.
Gibt HTTP Status Code 200 zurück solange die Applikation einwandfrei läuft. Im Fehlerfall wird der
Status Code 503 zurück gegeben.
Dieser Endpoint kann z.B. für die Health-Checks von Openshift verwendet werden.

## Mail

Der Endpoint **/healthz/mail?token=abcdefg123** prüft ob die Mails im Catch-All Konto regelmässig abgearbeitet werden. Ist dies nicht der Fall, wird der HTTP Status Code 503 zurück gegeben.
Der Zugriff ist nur mit einem gültigen Token möglich.
Um diesen Token für die entsprechende Umgebung zu erhalten kann auf der Konsole folgender Befehl verwendet werden:

```bundle exec rake app_status:auth_token```

Diesen Endpoint alle 10 Minuten zu triggern sollte völlig reichen. Bei jedem Request wird ein IMAP Login gemacht und das Catch-All Postfach auf länger nicht verarbeitete Nachrichten geprüft.

## True Mail

Der Endpoint **/healthz/truemail?token=abcdefg123** prüft ob Truemail erfolgreich in der aktuellen Umgebung E-Mails via MX/DNS Check prüfen kann. Dieser Check dient dazu Truemail zu debuggen. In einigen Umgebungen macht Truemail z.B. beim Speichern immer wieder mal Probleme. 

Gleicher token wie oben unter Mail.
