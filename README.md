# Exportação de Transações - CSV

Este projeto contém uma funcionalidade para exportar transações financeiras em formato CSV, agrupando-as por parcelas detalhadas ou parcela única.

## Funcionalidade

- Recebe um **payload JSON** com transações.
- Gera um **arquivo CSV** contendo as informações processadas.
- Cada transação terá uma **identificação única**.
- Parcelas detalhadas são tratadas individualmente.
- Transações sem parcelas detalhadas têm a data de liquidação prevista para 30 dias após a data de compra.
- As transações no CSV são agrupadas por `bandeira`, `data de liquidação` e `cnpj lojista`, somando o valor das parcelas.

## Endpoint

### `POST /exports`

Gera e retorna um CSV de transações.

#### Request

- **Headers**:
  - `Content-Type: application/json`
- **Body**:
  ```json
  {
    "transactions": [
      {
        "bandeira": "VISA",
        "cnpj_lojista": "12.345.678/0001-01",
        "data_compra": "2025-03-18",
        "valor_total": 122.08,
        "parcelas_detalhadas": [
          {
            "data_liquidacao": "2025-04-17",
            "valor": 20.35
          },
          ...
        ]
      },
      ...
    ]
  }
  ```

> Observação: Caso não exista o campo `parcelas_detalhadas`, será considerada uma parcela única e a data de liquidação será a `data_compra` + 30 dias.

#### Response

- Tipo: `text/csv`
- Exemplo de conteúdo:

  | identificacao_unica | bandeira | cnpj_lojista        | data_liquidacao | valor_total |
  |---------------------|----------|---------------------|-----------------|-------------|
  | uuid-gerado         | VISA     | 12.345.678/0001-01  | 2025-04-17      | 122.08      |

## Regras de negócio

- **Agrupamento**:
  - As transações são agrupadas prioritariamente pela bandeira (por exemplo, todas as transações MASTER vêm antes das VISA).
- **Parcela Única**:
  - Quando não houver data de liquidação (parcela única), para a data de liquidação será considerado a `data_compra` + 30 dias.
- **Identificação única**:
  - Cada linha no CSV terá um identificador único (`uuid`) gerado no momento da exportação (utilizando `SecureRamdom`.

## Testes

Testes de integração foram implementados para garantir:

- Geração correta do CSV com transações agrupadas.
- Geração correta do CSV com payload vazio.
- Validação da data de liquidação para transações de parcela única.

## Como rodar o projeto?

Este projeto foi configurado para ser executado em Docker. Siga as instruções abaixo para rodar o projeto no seu ambiente local.

### Build do Docker

Para construir a imagem Docker do projeto, rode o seguinte comando:

```bash
docker compose build
```

### Subir os containers

Após o build, execute o comando abaixo para iniciar os containers:

```bash
docker-compose up
```

Isso irá iniciar o serviço em http://localhost:3000/.

### Acessando o bash para rodar testes ou rubocop

Para acessar o bash do container do projeto, use o comando:

```bash
docker compose run web bash
```

Isso abrirá um shell dentro do container, onde você poderá rodar os testes ou o rubocop.

#### Rodar os testes

Dentro do container, você pode rodar os testes com o seguinte comando:

```bash
bundle exec rails test
```

#### Rodar o Rubocop

Para rodar o Rubocop e verificar os linters, execute:

```bash
bundle exec rubocop
```

## Estrutura de Diretórios

- `app/controllers/exports_controller.rb`: Implementação da exportação.
- `test/controllers/exports_controller_test.rb`: Testes de integração.
- `test/fixtures/files/payload_teste_tecnico.json`: Payload de exemplo usado nos testes.
