"""Add persistent maternal knowledge sources/chunks and minimize AI audit data.

Revision ID: 002_knowledge_rag
Revises: 001_initial_schema
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "002_knowledge_rag"
down_revision: Union[str, None] = "001_initial_schema"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "knowledge_sources",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("title", sa.String(length=512), nullable=False),
        sa.Column("issuing_organization", sa.String(length=255), nullable=False),
        sa.Column("original_url", sa.String(length=2048), nullable=False),
        sa.Column("publication_date", sa.Date(), nullable=True),
        sa.Column("last_reviewed_date", sa.Date(), nullable=True),
        sa.Column("ingested_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("version", sa.String(length=128), nullable=False),
        sa.Column("content_hash", sa.String(length=64), nullable=False),
        sa.Column("topic", sa.String(length=128), nullable=False),
        sa.Column("maternal_stages", sa.JSON(), nullable=False),
        sa.Column("jurisdiction", sa.String(length=128), nullable=False),
        sa.Column("source_type", sa.String(length=64), nullable=False),
        sa.Column("review_status", sa.String(length=64), nullable=False),
        sa.Column("license_note", sa.Text(), nullable=False),
        sa.Column("original_filename", sa.String(length=512), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_knowledge_sources_content_hash", "knowledge_sources", ["content_hash"])
    op.create_index("ix_knowledge_sources_topic", "knowledge_sources", ["topic"])
    op.create_index("ix_knowledge_sources_jurisdiction", "knowledge_sources", ["jurisdiction"])
    op.create_index("ix_knowledge_sources_review_status", "knowledge_sources", ["review_status"])
    op.create_table(
        "knowledge_chunks",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("source_id", sa.String(length=36), nullable=False),
        sa.Column("chunk_index", sa.Integer(), nullable=False),
        sa.Column("text", sa.Text(), nullable=False),
        sa.Column("section", sa.String(length=512), nullable=True),
        sa.Column("page_number", sa.Integer(), nullable=True),
        sa.Column("token_count", sa.Integer(), nullable=False),
        sa.Column("embedding", sa.JSON(), nullable=True),
        sa.Column("embedding_model", sa.String(length=128), nullable=False),
        sa.ForeignKeyConstraint(["source_id"], ["knowledge_sources.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("source_id", "chunk_index", name="uq_knowledge_source_chunk"),
    )
    op.create_index("ix_knowledge_chunks_source_id", "knowledge_chunks", ["source_id"])

    # The existing initial migration predates AIInteraction and does not create
    # this table, so add the privacy-minimized audit table here in full.
    op.create_table(
        "ai_interactions",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("user_query", sa.Text(), nullable=True),
        sa.Column("assistant_response", sa.Text(), nullable=True),
        sa.Column("query_hash", sa.String(length=64), nullable=True),
        sa.Column("safety_escalation_flagged", sa.Boolean(), nullable=False),
        sa.Column("cited_source_ids", sa.JSON(), nullable=True),
        sa.Column("latency_ms", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_ai_interactions_user_id", "ai_interactions", ["user_id"])
    op.create_index("ix_ai_interactions_query_hash", "ai_interactions", ["query_hash"])
    op.create_index("ix_ai_interactions_safety_escalation_flagged", "ai_interactions", ["safety_escalation_flagged"])


def downgrade() -> None:
    op.drop_index("ix_ai_interactions_safety_escalation_flagged", table_name="ai_interactions")
    op.drop_index("ix_ai_interactions_query_hash", table_name="ai_interactions")
    op.drop_index("ix_ai_interactions_user_id", table_name="ai_interactions")
    op.drop_table("ai_interactions")
    op.drop_index("ix_knowledge_chunks_source_id", table_name="knowledge_chunks")
    op.drop_table("knowledge_chunks")
    op.drop_index("ix_knowledge_sources_review_status", table_name="knowledge_sources")
    op.drop_index("ix_knowledge_sources_jurisdiction", table_name="knowledge_sources")
    op.drop_index("ix_knowledge_sources_topic", table_name="knowledge_sources")
    op.drop_index("ix_knowledge_sources_content_hash", table_name="knowledge_sources")
    op.drop_table("knowledge_sources")
