"""add spot_status table

Revision ID: 356babbac29f
Revises: 0001_initial_schema
Create Date: 2025-10-29 15:07:59.576906

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '356babbac29f'
down_revision: Union[str, Sequence[str], None] = '0001_initial_schema'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        'spot_status',
        sa.Column('run_id', sa.String(), nullable=False),
        sa.Column('ts_ms', sa.BigInteger(), nullable=False),
        sa.Column('spot_id', sa.String(), nullable=False),
        sa.Column('state', sa.String(), nullable=False),
        sa.Column('conf', sa.Float(), nullable=True),
        sa.ForeignKeyConstraint(['run_id'], ['runs.run_id'], ),
        sa.ForeignKeyConstraint(['spot_id'], ['stalls.id'], ),
        sa.PrimaryKeyConstraint('run_id', 'ts_ms', 'spot_id')
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_table('spot_status')
