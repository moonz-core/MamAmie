"""Initial database schema for MamAmie

Revision ID: 001_initial_schema
Revises:
Create Date: 2026-10-24 00:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = '001_initial_schema'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Users table
    op.create_table(
        'users',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('email', sa.String(length=255), nullable=False),
        sa.Column('hashed_password', sa.String(length=255), nullable=False),
        sa.Column('full_name', sa.String(length=255), nullable=False),
        sa.Column('phone_number', sa.String(length=32), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default=sa.text('1')),
        sa.Column('is_verified', sa.Boolean(), nullable=False, server_default=sa.text('0')),
        sa.Column('role', sa.String(length=32), nullable=False, server_default='user'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)

    # User profiles table
    op.create_table(
        'user_profiles',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('current_stage', sa.String(length=32), nullable=False, server_default='pregnant'),
        sa.Column('language_code', sa.String(length=10), nullable=False, server_default='en'),
        sa.Column('timezone', sa.String(length=64), nullable=False, server_default='Asia/Kolkata'),
        sa.Column('diet_preferences', sa.JSON(), nullable=True),
        sa.Column('food_allergies', sa.JSON(), nullable=True),
        sa.Column('notification_preferences', sa.JSON(), nullable=True),
        sa.Column('clinician_notes', sa.Text(), nullable=True),
        sa.Column('is_onboarding_completed', sa.Boolean(), nullable=False, server_default=sa.text('0')),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id')
    )


def downgrade() -> None:
    op.drop_table('user_profiles')
    op.drop_index(op.f('ix_users_email'), table_name='users')
    op.drop_table('users')
