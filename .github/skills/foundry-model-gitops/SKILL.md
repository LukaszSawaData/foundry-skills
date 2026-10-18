---
name: foundry-model-gitops
description: Wdrażanie, skalowanie i usuwanie modeli w Microsoft Foundry w tym repozytorium przez Terraform i Pull Request (GitOps). Używaj zawsze, gdy użytkownik chce wdrożyć nowy model, zmienić wersję lub pojemność albo usunąć deployment.
---

# Deploymenty modeli Foundry przez GitOps

W tym repozytorium modele wdraża wyłącznie pipeline po zatwierdzeniu Pull Requesta.
Twoja rola: sprawdzić, czy zmiana jest możliwa, przygotować ją w pliku Terraform i otworzyć PR.

## Zasady (bezwzględne)

- NIGDY nie uruchamiaj komend zmieniających Azure: az ... create/update/delete,
  az cognitiveservices account deployment create/delete, terraform apply,
  terraform destroy, azd provision/deploy.
- Wolno Ci uruchamiać tylko komendy odczytu (list, show) oraz
  terraform fmt, terraform init -backend=false, terraform validate.
- Jedynym plikiem, który zmieniasz, jest infra/models.auto.tfvars.
- Nie scalaj PR. Zatwierdza go człowiek.

## Kontekst

- Region, subskrypcja, prefiks, resource group: plik infra/env.auto.tfvars.
- Zasób Foundry: <prefix>-foundry w resource group resource_group_name.
- Format wpisu w infra/models.auto.tfvars:

~~~hcl
  "nazwa-deploymentu" = {
    model_name    = "gpt-4.1-nano"
    model_version = "2025-04-14"
    capacity      = 10
  }
~~~

Nazwa deploymentu: małe litery, cyfry, myślniki (np. gpt-41-nano), bez kropek.

## Procedura: nowy model / zmiana wersji / zmiana pojemności

1. Stan obecny: przeczytaj infra/models.auto.tfvars i infra/env.auto.tfvars.
   Sprawdź, czy deployment o tej nazwie już istnieje.

2. Dostępność modelu w regionie:

~~~bash
az cognitiveservices model list -l <location> --query "[?model.name=='<model>'].{version:model.version, skus:join(',', model.skus[].name), lifecycle:model.lifecycleStatus}" -o table
~~~

   Bez podanej wersji wybierz najnowszą GenerallyAvailable z wymaganym SKU.
   Jeśli modelu nie ma w regionie - przerwij i powiedz to użytkownikowi.

3. Quota:

~~~bash
az cognitiveservices usage list -l <location> --query "[?contains(name.value, '<SKU>.<model>')].{name:name.value, used:currentValue, limit:limit}" -o table
~~~

   Wolne = limit - used. Nowa pojemność (lub przyrost) musi się zmieścić.
   Jeśli nie - przerwij i zaproponuj mniejszą pojemność.

4. Zmień plik infra/models.auto.tfvars: dodaj lub zmień jeden wpis, innych nie ruszaj.

5. Format i składnia:

~~~bash
cd infra && terraform fmt && terraform init -backend=false -input=false >/dev/null && terraform validate; cd ..
~~~

6. Gałąź, commit, PR:

~~~bash
git checkout main && git pull
git checkout -b model/<nazwa-deploymentu>
git add infra/models.auto.tfvars
git commit -m "Foundry: <co się zmienia>"
git push -u origin HEAD
gh pr create --title "Foundry: <co się zmienia>" --body "<opis wg szablonu>"
~~~

   Szablon opisu PR:
   - Zmiana: model, wersja, SKU, pojemność; było -> będzie
   - Dostępność w regionie: wersja, lifecycle
   - Quota SKU.model: użyte x / limit y -> po zmianie z
   - Wdrożenie: plan w Actions -> Summary; po merge wymagana akceptacja w środowisku production

7. Podsumuj użytkownikowi: link do PR i informację, gdzie zobaczyć plan.

## Procedura: usunięcie modelu

1. Usuń wpis z infra/models.auto.tfvars.
2. Kroki 5-7, tytuł PR: "Foundry: usunięcie <nazwa>".
3. W opisie PR wyraźnie zaznacz USUNIĘCIE - aplikacje używające deploymentu przestaną działać.

## Czego nie robić

- Nie twórz zasobów Foundry, projektów ani resource group.
- Nie zmieniaj infra/*.tf, workflowów ani bootstrap/.
- Nie zgaduj wersji ani quota - zawsze sprawdź komendami z kroków 2-3.
