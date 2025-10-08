"""add conf to spot_status

Revision ID: 9f6c14e00cac
Revises: 64dd65687d38
Create Date: 2025-10-08 10:14:21.885872

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '9f6c14e00cac'
down_revision: Union[str, Sequence[str], None] = '64dd65687d38'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column('spot_status', sa.Column('conf', sa.Float(), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column('spot_status', 'conf')