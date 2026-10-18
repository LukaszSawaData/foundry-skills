# Modele w Microsoft Foundry. Każda zmiana = PR -> plan -> akceptacja -> apply.
#
# klucz         = nazwa deploymentu (małe litery, cyfry, myślniki)
# model_name    = nazwa modelu z katalogu Foundry
# model_version = wersja dostępna w regionie
# sku           = GlobalStandard (domyślnie, można pominąć)
# capacity      = tysiące tokenów na minutę (TPM) - sprawdź quota

deployments = {
  "gpt-41-mini" = {
    model_name    = "gpt-4.1-mini"
    model_version = "2025-04-14"
    capacity      = 10
  }
}
