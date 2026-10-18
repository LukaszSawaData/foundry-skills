# Wdrażanie modeli w Microsoft Foundry przez skill + Terraform + Pull Request

## Idea

Modele w Foundry wdrażamy bez klikania i bez ręcznych komend:

1. Mówimy asystentowi AI (GitHub Copilot CLI): "wdróż model X".
2. Asystent, prowadzony przez **skill** (plik `SKILL.md`), sprawdza dostępność
   modelu i quota, **dopisuje model do pliku Terraform** i otwiera **Pull Request**.
3. Pipeline pokazuje `terraform plan`, czyli co dokładnie się zmieni.
4. Po merge i **akceptacji człowieka** pipeline wykonuje `terraform apply`.

Stan Terraforma trzymamy w Azure Storage (jedno źródło prawdy).
Asystent AI **nigdy** nie zmienia Azure sam - przygotowuje tylko zmianę do przeglądu.

## Wymagania

- WSL / Linux: `az`, `terraform`, `gh`, `git`, Node.js 22, `copilot` (GitHub Copilot CLI)
- Logowanie do Azure **z MFA**
- Rola Owner na subskrypcji

## Krok 1. Folder i repozytorium

```bash
mkdir -p ~/foundry-skills && cd ~/foundry-skills
git init -b main
gh repo create foundry-skills --public
git remote add origin https://github.com/$(gh api user --jq .login)/foundry-skills.git
```

Repo tworzymy puste - kod wypychamy dopiero po bootstrapie (krok 4), bo pipeline
potrzebuje zmiennych, które ustawia bootstrap.

## Krok 2. Bootstrap - pliki

Bootstrap to mały Terraform uruchamiany **raz, lokalnie**, ze stanem lokalnym (nie w Git).
Przygotowuje wszystko, czego pipeline potrzebuje, żeby potem sam zarządzał infrastrukturą.

| Plik | Co tworzy |
|---|---|
| `bootstrap/state.tf` | RG na stan, pustą RG na Foundry, storage account + kontener `tfstate` |
| `bootstrap/identity.tf` | managed identity dla GitHub Actions |
| `bootstrap/federation.tf` | OIDC: logowanie bez haseł z PR, z `main` i ze środowiska `production` |
| `bootstrap/roles.tf` | Contributor na RG Foundry, dostęp do stanu (pipeline i my) |
| `bootstrap/github.tf` | zmienne GitHub Actions (ID, nazwy RG, storage) |
| `bootstrap/environment.tf` | środowisko `production` z wymaganą akceptacją, tylko z `main` |
| `bootstrap/outputs.tf` | lokalne pliki `infra/backend.hcl` i `infra/env.auto.tfvars` |

Ważne decyzje:
- **Managed identity zamiast app registration** - nie wymaga uprawnień do Entra ID.
- **Subject OIDC z numerycznymi ID** (`owner@id/repo@id`) - taki format wysyła teraz GitHub.
- **Storage bez kluczy** (`shared_access_key_enabled = false`) - dostęp tylko przez Entra ID.

## Krok 4. Infrastruktura Foundry (`infra/`)

Terraform zarządzany przez pipeline. Stan w Azure Storage.

| Plik | Zawartość |
|---|---|
| `infra/providers.tf` | providery `azurerm` + `azapi`, backend `azurerm` (parametry z zewnątrz) |
| `infra/variables.tf` | zmienne + walidacja listy modeli (nazwa, capacity 1-100) |
| `infra/foundry.tf` | zasób Foundry (AI Services) + projekt `models` |
| `infra/deployments.tf` | `for_each` po liście modeli → jeden deployment na wpis |
| `infra/models.auto.tfvars` | **LISTA MODELI** - jedyny plik zmieniany przy wdrażaniu modeli |

Lokalny podgląd (bez wdrażania):

```bash
cd infra
terraform init -backend-config=backend.hcl
terraform plan
```

Zasada: **lokalnie tylko `plan`**. `apply` wykonuje wyłącznie pipeline.

## Krok 5. Pipeline (`.github/workflows/terraform.yml`)

| Job | Kiedy | Co robi |
|---|---|---|
| `plan` | PR zmieniający `infra/` | `fmt -check` → `init` → `validate` → `plan`; plan w zakładce **Summary** runu |
| `apply` | push na `main` | **czeka na akceptację** (`environment: production`), potem `apply -parallelism=1` |

- Logowanie: OIDC (`ARM_USE_OIDC=true`) tożsamością z bootstrapu - brak sekretów w repo.
- Wartości zmiennych Terraform pochodzą ze zmiennych GitHub Actions (`TF_VAR_*`).
- `concurrency` - nigdy dwa runy naraz na tym samym stanie.
- `-parallelism=1` - Foundry nie lubi równoległych zmian deploymentów na jednym zasobie.

## Krok 7. Skill dla Copilota

Plik: .github/skills/foundry-model-gitops/SKILL.md

Skill = przepis dla asystenta AI. Plik Markdown z nagłówkiem YAML (name, description).
Copilot CLI czyta skille projektu z .github/skills/, a osobiste z ~/.copilot/skills/.

Co narzuca nasz skill:

| Wolno | Nie wolno |
|---|---|
| komendy odczytu: az ... list/show | az ... create/update/delete |
| terraform fmt, init -backend=false, validate | terraform apply/destroy |
| zmiana infra/models.auto.tfvars | zmiana *.tf, workflowów, bootstrapu |
| gałąź, commit, push, gh pr create | merge PR |

Procedura skilla: sprawdź model w regionie -> sprawdź quota -> zmień listę modeli ->
fmt + validate -> PR z opisem sprawdzeń.

Uwaga: w plikach tworzonych przez heredoc w czacie bloki kodu wewnątrz Markdown
zapisujemy jako ~~~ zamiast trzech odwrotnych apostrofów - inaczej kopiowanie się urywa.

## Krok 10. Cykl życia modelu

Każda operacja = to samo polecenie do Copilota + PR + akceptacja:

| Polecenie | Zmiana w models.auto.tfvars | terraform plan |
|---|---|---|
| "Wdróż gpt-5.4-nano w wersji 2026-03-17 z pojemnością 10" | nowy wpis | 1 to add |
| "Zwiększ pojemność gpt-54-nano do 20" | capacity 10 -> 20 | 1 to change |
| "Usuń deployment gpt-54-nano" | wpis usunięty | 1 to destroy |

## Podsumowanie

| Kto | Rola |
|---|---|
| Skill (SKILL.md) | wiedza: jak sprawdzić model, wersję, quota; czego nie wolno robić |
| Copilot | wykonawca: sprawdza, edytuje jeden plik, otwiera PR |
| Pipeline | plan w PR, apply po akceptacji |
| Człowiek | review PR i akceptacja wdrożenia |
| Terraform + stan w Azure | jedno źródło prawdy o tym, co jest wdrożone |

## Sprzątanie

~~~bash
cd infra && terraform init -backend-config=backend.hcl && terraform destroy
cd ../bootstrap && export GITHUB_TOKEN=$(gh auth token) && terraform destroy
~~~

