#!/usr/bin/env python3
"""
Render Jinja templates and deploy SQL to Snowflake.
Usage: python render_and_deploy.py <ENVIRONMENT> [--connection <name>]
Example: python render_and_deploy.py PROD --connection myconn
"""

import os
import sys
import glob
import yaml
import argparse
from jinja2 import Template
import subprocess

CONNECTION = 'default'

def load_config(env: str) -> dict:
    """Load configuration from manifest.yml for specified environment."""
    with open('manifest.yml', 'r') as f:
        manifest = yaml.safe_load(f)
    
    if env not in manifest.get('configurations', {}):
        raise ValueError(f"Environment '{env}' not found in manifest.yml")
    
    return manifest['configurations'][env]

def render_sql(sql_content: str, config: dict) -> str:
    """Render Jinja template with configuration variables."""
    template = Template(sql_content)
    return template.render(**config)

def execute_sql(sql: str, description: str = ""):
    """Execute SQL using Snow CLI."""
    print(f"\n{'='*60}")
    print(f"Executing: {description}")
    print(f"{'='*60}")
    
    statements = [s.strip() for s in sql.split(';') if s.strip()]
    
    for stmt in statements:
        if not stmt:
            continue
        
        stmt_preview = stmt[:100] + "..." if len(stmt) > 100 else stmt
        print(f"\n> {stmt_preview}")
        
        try:
            result = subprocess.run(
                ['snow', 'sql', '-q', stmt, '-c', CONNECTION],
                capture_output=True,
                text=True,
                timeout=120
            )
            if result.returncode != 0:
                print(f"  WARNING: {result.stderr}")
            else:
                print(f"  OK")
        except subprocess.TimeoutExpired:
            print(f"  WARNING: Statement timed out")
        except Exception as e:
            print(f"  WARNING: {e}")

def main():
    global CONNECTION
    
    parser = argparse.ArgumentParser(description='Render Jinja templates and deploy SQL to Snowflake')
    parser.add_argument('environment', help='Target environment (DEV or PROD)')
    parser.add_argument('-c', '--connection', default='default', help='Snow CLI connection name')
    args = parser.parse_args()
    
    env = args.environment.upper()
    CONNECTION = args.connection
    
    print(f"\n{'#'*60}")
    print(f"# Deploying to {env} (connection: {CONNECTION})")
    print(f"{'#'*60}")
    
    config = load_config(env)
    print(f"\nConfiguration loaded for {env}:")
    for key, value in config.items():
        print(f"  {key}: {value}")
    
    sql_files = sorted(glob.glob('definitions/*.sql'))
    print(f"\nFound {len(sql_files)} SQL files to process")
    
    for sql_file in sql_files:
        print(f"\n{'='*60}")
        print(f"Processing: {sql_file}")
        print(f"{'='*60}")
        
        with open(sql_file, 'r') as f:
            raw_sql = f.read()
        
        rendered_sql = render_sql(raw_sql, config)
        
        execute_sql(rendered_sql, sql_file)
    
    print(f"\n{'#'*60}")
    print(f"# Deployment to {env} completed!")
    print(f"{'#'*60}\n")

if __name__ == '__main__':
    main()
