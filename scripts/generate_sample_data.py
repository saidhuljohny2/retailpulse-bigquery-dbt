#!/usr/bin/env python3
"""Generate realistic synthetic retail data for RetailPulse."""

from __future__ import annotations

import argparse
import logging
import os
import random
import uuid
from datetime import datetime, timedelta
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from faker import Faker

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

fake = Faker()
Faker.seed(42)
random.seed(42)

DEPARTMENTS = ["Electronics", "Clothing", "Home & Garden", "Sports", "Beauty", "Books"]
CATEGORIES = {
    "Electronics": ["Laptops", "Phones", "Tablets", "Accessories", "Audio"],
    "Clothing": ["Men", "Women", "Kids", "Shoes", "Accessories"],
    "Home & Garden": ["Furniture", "Kitchen", "Decor", "Outdoor", "Tools"],
    "Sports": ["Fitness", "Outdoor", "Team Sports", "Cycling", "Swimming"],
    "Beauty": ["Skincare", "Makeup", "Haircare", "Fragrance", "Tools"],
    "Books": ["Fiction", "Non-Fiction", "Children", "Textbooks", "Comics"],
}
BRANDS = [
    "TechPro", "StyleMax", "HomeEssentials", "ActiveLife", "GlowUp",
    "ReadWell", "UrbanWear", "SmartGear", "NaturePlus", "EliteBrand",
]
ORDER_STATUSES = ["completed", "cancelled", "pending", "shipped", "returned"]
PAYMENT_STATUSES = ["paid", "pending", "failed", "refunded"]
PAYMENT_METHODS = ["credit_card", "debit_card", "paypal", "apple_pay", "google_pay"]
CUSTOMER_STATUSES = ["active", "inactive", "suspended"]
PRODUCT_STATUSES = ["active", "discontinued", "out_of_stock"]
RETURN_REASONS = ["defective", "wrong_item", "not_as_described", "changed_mind", "damaged"]
RETURN_STATUSES = ["approved", "pending", "rejected"]
EVENT_TYPES = ["page_view", "product_view", "add_to_cart", "checkout_start", "purchase"]
DEVICE_TYPES = ["desktop", "mobile", "tablet"]
TRAFFIC_SOURCES = ["organic", "paid_search", "social", "email", "direct", "referral"]
CAMPAIGN_CHANNELS = ["email", "social", "search", "display", "affiliate"]
CAMPAIGN_STATUSES = ["active", "completed", "paused", "draft"]
US_STATES = [
    "CA", "TX", "NY", "FL", "IL", "PA", "OH", "GA", "NC", "MI",
    "NJ", "VA", "WA", "AZ", "MA", "TN", "IN", "MO", "MD", "WI",
]


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="Generate synthetic retail data.")
    parser.add_argument("--customers", type=int, default=5000, help="Number of customers")
    parser.add_argument("--products", type=int, default=500, help="Number of products")
    parser.add_argument("--orders", type=int, default=50000, help="Number of orders")
    parser.add_argument(
        "--order-items", type=int, default=100000, help="Number of order items"
    )
    parser.add_argument(
        "--web-events", type=int, default=200000, help="Number of web events"
    )
    parser.add_argument(
        "--output-dir",
        type=str,
        default=None,
        help="Output directory for CSV files",
    )
    return parser.parse_args()


def generate_categories() -> pd.DataFrame:
    """Generate product categories."""
    records = []
    category_id = 1
    for department, cats in CATEGORIES.items():
        for cat_name in cats:
            records.append({
                "category_id": category_id,
                "category_name": cat_name,
                "department": department,
                "created_at": fake.date_time_between(
                    start_date="-3y", end_date="-1y"
                ).isoformat(),
            })
            category_id += 1
    return pd.DataFrame(records)


def generate_customers(n: int) -> pd.DataFrame:
    """Generate customer records."""
    records = []
    for i in range(1, n + 1):
        created = fake.date_time_between(start_date="-3y", end_date="-30d")
        records.append({
            "customer_id": i,
            "first_name": fake.first_name(),
            "last_name": fake.last_name(),
            "email": fake.unique.email(),
            "phone": fake.phone_number()[:20],
            "city": fake.city(),
            "state": random.choice(US_STATES),
            "country": "US",
            "postal_code": fake.zipcode(),
            "signup_date": created.date().isoformat(),
            "customer_status": random.choices(
                CUSTOMER_STATUSES, weights=[0.75, 0.20, 0.05]
            )[0],
            "created_at": created.isoformat(),
            "updated_at": fake.date_time_between(
                start_date=created, end_date="now"
            ).isoformat(),
        })
    return pd.DataFrame(records)


def generate_products(n: int, categories: pd.DataFrame) -> pd.DataFrame:
    """Generate product records."""
    category_ids = categories["category_id"].tolist()
    records = []
    for i in range(1, n + 1):
        created = fake.date_time_between(start_date="-2y", end_date="-30d")
        cost = round(random.uniform(5.0, 200.0), 2)
        margin = random.uniform(1.2, 2.5)
        records.append({
            "product_id": i,
            "product_name": fake.catch_phrase()[:80],
            "category_id": random.choice(category_ids),
            "brand": random.choice(BRANDS),
            "unit_price": round(cost * margin, 2),
            "cost_price": cost,
            "product_status": random.choices(
                PRODUCT_STATUSES, weights=[0.80, 0.10, 0.10]
            )[0],
            "created_at": created.isoformat(),
            "updated_at": fake.date_time_between(
                start_date=created, end_date="now"
            ).isoformat(),
        })
    return pd.DataFrame(records)


def generate_campaigns(n: int = 20) -> pd.DataFrame:
    """Generate marketing campaign records."""
    records = []
    for i in range(1, n + 1):
        start = fake.date_between(start_date="-2y", end_date="-30d")
        end = start + timedelta(days=random.randint(7, 90))
        records.append({
            "campaign_id": i,
            "campaign_name": f"Campaign_{fake.word().title()}_{i}",
            "channel": random.choice(CAMPAIGN_CHANNELS),
            "campaign_start_date": start.isoformat(),
            "campaign_end_date": end.isoformat(),
            "budget_amount": round(random.uniform(1000, 50000), 2),
            "campaign_status": random.choice(CAMPAIGN_STATUSES),
        })
    return pd.DataFrame(records)


def generate_orders(
    n: int, customers: pd.DataFrame, campaigns: pd.DataFrame
) -> pd.DataFrame:
    """Generate order records."""
    customer_ids = customers["customer_id"].tolist()
    campaign_ids = campaigns["campaign_id"].tolist()
    records = []
    for i in range(1, n + 1):
        created = fake.date_time_between(start_date="-2y", end_date="now")
        order_status = random.choices(
            ORDER_STATUSES, weights=[0.70, 0.05, 0.05, 0.15, 0.05]
        )[0]
        records.append({
            "order_id": i,
            "customer_id": random.choice(customer_ids),
            "order_date": created.date().isoformat(),
            "order_status": order_status,
            "payment_status": random.choices(
                PAYMENT_STATUSES, weights=[0.80, 0.05, 0.05, 0.10]
            )[0],
            "shipping_city": fake.city(),
            "shipping_state": random.choice(US_STATES),
            "shipping_country": "US",
            "campaign_id": random.choice(campaign_ids) if random.random() < 0.4 else None,
            "created_at": created.isoformat(),
            "updated_at": fake.date_time_between(
                start_date=created, end_date="now"
            ).isoformat(),
        })
    return pd.DataFrame(records)


def generate_order_items(
    n: int, orders: pd.DataFrame, products: pd.DataFrame
) -> pd.DataFrame:
    """Generate order item records."""
    order_ids = orders["order_id"].tolist()
    product_map = products.set_index("product_id")
    records = []
    for i in range(1, n + 1):
        product_id = random.choice(product_map.index.tolist())
        product = product_map.loc[product_id]
        qty = random.randint(1, 5)
        unit_price = product["unit_price"]
        discount = round(unit_price * qty * random.uniform(0, 0.15), 2)
        tax = round((unit_price * qty - discount) * 0.08, 2)
        records.append({
            "order_item_id": i,
            "order_id": random.choice(order_ids),
            "product_id": product_id,
            "quantity": qty,
            "unit_price": unit_price,
            "discount_amount": discount,
            "tax_amount": tax,
            "created_at": fake.date_time_between(
                start_date="-2y", end_date="now"
            ).isoformat(),
        })
    return pd.DataFrame(records)


def generate_payments(orders: pd.DataFrame) -> pd.DataFrame:
    """Generate payment records for completed/shipped orders."""
    eligible = orders[orders["order_status"].isin(["completed", "shipped"])]
    records = []
    for idx, order in eligible.iterrows():
        records.append({
            "payment_id": len(records) + 1,
            "order_id": order["order_id"],
            "payment_method": random.choice(PAYMENT_METHODS),
            "payment_amount": round(random.uniform(20.0, 500.0), 2),
            "payment_status": "paid" if order["payment_status"] == "paid" else order["payment_status"],
            "payment_date": order["order_date"],
        })
    return pd.DataFrame(records)


def generate_returns(order_items: pd.DataFrame) -> pd.DataFrame:
    """Generate return records (~5% of order items)."""
    sample_size = max(1, int(len(order_items) * 0.05))
    sample = order_items.sample(n=sample_size, random_state=42)
    records = []
    for idx, item in sample.iterrows():
        net = item["unit_price"] * item["quantity"] - item["discount_amount"]
        records.append({
            "return_id": len(records) + 1,
            "order_item_id": item["order_item_id"],
            "return_date": fake.date_between(
                start_date="-1y", end_date="today"
            ).isoformat(),
            "return_reason": random.choice(RETURN_REASONS),
            "refund_amount": round(net * random.uniform(0.5, 1.0), 2),
            "return_status": random.choices(
                RETURN_STATUSES, weights=[0.70, 0.20, 0.10]
            )[0],
        })
    return pd.DataFrame(records)


def generate_web_events(
    n: int,
    customers: pd.DataFrame,
    products: pd.DataFrame,
    campaigns: pd.DataFrame,
) -> pd.DataFrame:
    """Generate web event records."""
    customer_ids = customers["customer_id"].tolist()
    product_ids = products["product_id"].tolist()
    campaign_ids = campaigns["campaign_id"].tolist()
    records = []
    for i in range(1, n + 1):
        records.append({
            "event_id": str(uuid.uuid4()),
            "customer_id": random.choice(customer_ids) if random.random() < 0.7 else None,
            "session_id": str(uuid.uuid4()),
            "event_timestamp": fake.date_time_between(
                start_date="-1y", end_date="now"
            ).isoformat(),
            "event_type": random.choices(
                EVENT_TYPES, weights=[0.40, 0.25, 0.15, 0.10, 0.10]
            )[0],
            "page_name": random.choice(
                ["home", "product_detail", "category", "cart", "checkout", "search"]
            ),
            "product_id": random.choice(product_ids) if random.random() < 0.6 else None,
            "device_type": random.choice(DEVICE_TYPES),
            "traffic_source": random.choice(TRAFFIC_SOURCES),
            "campaign_id": random.choice(campaign_ids) if random.random() < 0.3 else None,
        })
    return pd.DataFrame(records)


def save_dataframes(dataframes: dict[str, pd.DataFrame], output_dir: Path) -> None:
    """Save dataframes to CSV files."""
    output_dir.mkdir(parents=True, exist_ok=True)
    for name, df in dataframes.items():
        path = output_dir / f"{name}.csv"
        df.to_csv(path, index=False)
        logger.info("Wrote %s records to %s", len(df), path)


def normalize_nullable_ids(dataframes: dict[str, pd.DataFrame]) -> None:
    """Keep nullable integer IDs from being serialized as floats in CSV output."""
    nullable_id_columns = {
        "orders": ["campaign_id"],
        "web_events": ["customer_id", "product_id", "campaign_id"],
    }
    for table_name, columns in nullable_id_columns.items():
        for column in columns:
            dataframes[table_name][column] = dataframes[table_name][column].astype("Int64")


def main() -> None:
    """Generate all synthetic retail data files."""
    args = parse_args()
    project_root = Path(__file__).resolve().parent.parent
    load_dotenv(project_root / ".env")

    output_dir = Path(
        args.output_dir or project_root / "data" / "sample_data"
    )

    logger.info("Generating synthetic retail data...")
    logger.info(
        "Counts: customers=%d, products=%d, orders=%d, "
        "order_items=%d, web_events=%d",
        args.customers,
        args.products,
        args.orders,
        args.order_items,
        args.web_events,
    )

    categories = generate_categories()
    customers = generate_customers(args.customers)
    products = generate_products(args.products, categories)
    campaigns = generate_campaigns()
    orders = generate_orders(args.orders, customers, campaigns)
    order_items = generate_order_items(args.order_items, orders, products)
    payments = generate_payments(orders)
    returns = generate_returns(order_items)
    web_events = generate_web_events(
        args.web_events, customers, products, campaigns
    )

    dataframes = {
        "customers": customers,
        "categories": categories,
        "products": products,
        "orders": orders,
        "order_items": order_items,
        "payments": payments,
        "returns": returns,
        "web_events": web_events,
        "marketing_campaigns": campaigns,
    }

    normalize_nullable_ids(dataframes)
    save_dataframes(dataframes, output_dir)
    logger.info("Data generation complete.")


if __name__ == "__main__":
    main()
