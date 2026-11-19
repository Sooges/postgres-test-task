# Тестове завдання: PostgreSQL

Два інстанси PostgreSQL 17 у Docker: `primary` і `replica`.

## Запуск

```bash
docker compose up -d --build
```

| Інстанс | Порт | База | Користувач / пароль |
|---|---|---|---|
| primary | 5433 | appdb | postgres / postgres |
| replica | 5434 | appdb | postgres / postgres |

Перевірка всіх пунктів:

```bash
docker exec privat-task-primary psql -U postgres -d appdb -f checks/primary.sql
docker exec privat-task-replica psql -U postgres -d appdb -f checks/replica.sql
```

Помилка `duplicate key value violates unique constraint` у блоці 3 очікувана: це перевірка унікальності.

## 1. Партиціонована таблиця

Файл: `sql/shared/01_table.sql`

Таблиця `t1` партиціонована по діапазону дати, одна партиція на місяць.

| Поле | Тип | |
|---|---|---|
| `op_date` | `timestamptz` | дата |
| `id` | `bigint` | айді |
| `amount` | `numeric(18,2)` | сума |
| `state` | `smallint` | стан, 0 або 1 |
| `operation_guid` | `uuid` | гуід операції |
| `message` | `jsonb` | повідомлення: `account`, `client_id`, `op_type` (`online` / `offline`) |

Первинний ключ `(id, op_date)`. Партиції створює функція `t1_ensure_partitions`, щоденне завдання тримає запас на два місяці вперед (`sql/shared/02_partitions.sql`).

## 2. Генерація даних

Файл: `sql/primary/04_generate.sql`

Процедура `t1_generate(p_rows, p_months)` заповнює таблицю випадковими даними. За замовчуванням це 120 000 рядків за останні 4 місяці, 1000 клієнтів. Викликається під час першого запуску бази.

## 3. Унікальність гуід операції

Файл: `sql/primary/03_guid_uniqueness.sql`

Унікальний індекс на партиціонованій таблиці мусить містити ключ партиціонування, тому `UNIQUE (operation_guid)` створити не можна. Унікальність забезпечує окрема таблиця `t1_operation_guid` з первинним ключем по гуід. Тригери на `t1` оновлюють її при вставці, зміні гуід і видаленні рядка.

## 4. Додавання запису кожні 5 секунд

Файл: `sql/primary/06_jobs.sql`

Планувальник — розширення `pg_cron`. Завдання `t1-add-operation` кожні 5 секунд викликає процедуру `t1_add_operation`, яка додає один рядок зі станом 0.

## 5. Оновлення стану кожні 3 секунди

Файл: `sql/primary/06_jobs.sql`

Завдання `t1-confirm-operations` кожні 3 секунди викликає процедуру `t1_confirm_operations`. Якщо кількість секунд поточного часу парна, стан змінюється з 0 на 1 у рядків з парним айді, інакше з непарним.

## 6. Матеріалізоване представлення

Файл: `sql/primary/05_client_totals.sql`

Представлення `t1_client_totals` зберігає загальну суму по айді клієнта і типу операції для рядків зі станом 1. Тригер на оновлення `t1` перевіряє, чи був перехід стану з 0 на 1, і в такому разі виконує `REFRESH MATERIALIZED VIEW CONCURRENTLY`.

## 7. Реплікація

Файли: `sql/primary/07_publication.sh`, `sql/replica/03_subscription.sh`

Логічна реплікація таблиці `t1`. На `primary` створено роль для реплікації і публікацію `t1_pub`, на `replica` — підписку `t1_sub`. Репліка отримує початкову копію даних і далі всі вставки, оновлення та видалення.
