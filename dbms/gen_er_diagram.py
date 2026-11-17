#!/usr/bin/env python3
"""
Generate a professional Crow's Foot ER diagram for AI Web Builder database.
Outputs to dbms/02_er_diagram.png.
"""

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, Rectangle, Circle, Polygon
import numpy as np
import os

# Figure & Canvas Setup
fig = plt.figure(figsize=(18, 22), dpi=200)
ax = fig.add_axes([0, 0, 1, 1])
ax.set_xlim(0, 1800)
ax.set_ylim(2200, 0)  # Top-down coordinates (0 at top, 2200 at bottom)
ax.axis('off')

# Styling Themes for Entities
THEMES = {
    'users': {
        'border': '#2563EB',      # Deep Blue
        'header_bg': '#DBEAFE',   # Light Blue
        'row_bg': '#F8FAFC',
        'text': '#1E3A8A',
        'grid': '#BFDBFE'
    },
    'sessions': {
        'border': '#0D9488',      # Teal
        'header_bg': '#CCFBF1',
        'row_bg': '#F0FDFA',
        'text': '#115E59',
        'grid': '#99F6E4'
    },
    'accounts': {
        'border': '#7C3AED',      # Purple
        'header_bg': '#EDE9FE',
        'row_bg': '#FAF5FF',
        'text': '#5B21B6',
        'grid': '#DDD6FE'
    },
    'verifications': {
        'border': '#64748B',      # Slate
        'header_bg': '#F1F5F9',
        'row_bg': '#F8FAFC',
        'text': '#334155',
        'grid': '#E2E8F0'
    },
    'subscription_plans': {
        'border': '#EA580C',      # Orange
        'header_bg': '#FFEDD5',
        'row_bg': '#FFF7ED',
        'text': '#9A3412',
        'grid': '#FED7AA'
    },
    'transactions': {
        'border': '#059669',      # Emerald Green
        'header_bg': '#D1FAE5',
        'row_bg': '#ECFDF5',
        'text': '#065F46',
        'grid': '#A7F3D0'
    },
    'website_projects': {
        'border': '#4F46E5',      # Indigo
        'header_bg': '#E0E7FF',
        'row_bg': '#EEF2FF',
        'text': '#3730A3',
        'grid': '#C7D2FE'
    },
    'conversations': {
        'border': '#DB2777',      # Pink / Rose
        'header_bg': '#FCE7F3',
        'row_bg': '#FDF2F8',
        'text': '#9D174D',
        'grid': '#FBCFE8'
    },
    'versions': {
        'border': '#D97706',      # Amber
        'header_bg': '#FEF3C7',
        'row_bg': '#FFFBEB',
        'text': '#92400E',
        'grid': '#FDE68A'
    }
}

TABLES = {
    'users': {
        'x': 720, 'y': 150, 'w': 360,
        'cols': [
            ('text', 'id', 'PK'),
            ('varchar(255)', 'email', 'UK'),
            ('varchar(255)', 'name', ''),
            ('text', 'image', ''),
            ('integer', 'total_creation', ''),
            ('integer', 'credits', ''),
            ('boolean', 'email_verified', ''),
            ('timestamptz', 'created_at', ''),
            ('timestamptz', 'updated_at', '')
        ]
    },
    'sessions': {
        'x': 180, 'y': 150, 'w': 340,
        'cols': [
            ('text', 'id', 'PK'),
            ('text', 'user_id', 'FK'),
            ('text', 'token', 'UK'),
            ('timestamptz', 'expires_at', ''),
            ('text', 'ip_address', ''),
            ('text', 'user_agent', ''),
            ('timestamptz', 'created_at', ''),
            ('timestamptz', 'updated_at', '')
        ]
    },
    'accounts': {
        'x': 1260, 'y': 150, 'w': 380,
        'cols': [
            ('text', 'id', 'PK'),
            ('text', 'user_id', 'FK'),
            ('varchar(50)', 'provider_id', ''),
            ('varchar(255)', 'account_id', ''),
            ('text', 'access_token', ''),
            ('text', 'refresh_token', ''),
            ('text', 'id_token', ''),
            ('timestamptz', 'access_token_expires_at', ''),
            ('timestamptz', 'refresh_token_expires_at', ''),
            ('text', 'scope', ''),
            ('text', 'password', ''),
            ('timestamptz', 'created_at', ''),
            ('timestamptz', 'updated_at', '')
        ]
    },
    'verifications': {
        'x': 180, 'y': 620, 'w': 340,
        'cols': [
            ('text', 'id', 'PK'),
            ('text', 'identifier', ''),
            ('text', 'value', ''),
            ('timestamptz', 'expires_at', ''),
            ('timestamptz', 'created_at', ''),
            ('timestamptz', 'updated_at', '')
        ]
    },
    'subscription_plans': {
        'x': 180, 'y': 970, 'w': 340,
        'cols': [
            ('varchar(50)', 'plan_id', 'PK'),
            ('varchar(100)', 'name', ''),
            ('integer', 'credits', ''),
            ('numeric(10,2)', 'amount_usd', ''),
            ('boolean', 'is_active', ''),
            ('timestamptz', 'created_at', '')
        ]
    },
    'transactions': {
        'x': 180, 'y': 1360, 'w': 350,
        'cols': [
            ('uuid', 'id', 'PK'),
            ('text', 'user_id', 'FK'),
            ('varchar(50)', 'plan_id', 'FK'),
            ('numeric(10,2)', 'amount', ''),
            ('integer', 'credits', ''),
            ('boolean', 'is_paid', ''),
            ('varchar(255)', 'stripe_session_id', ''),
            ('timestamptz', 'created_at', ''),
            ('timestamptz', 'updated_at', '')
        ]
    },
    'website_projects': {
        'x': 710, 'y': 780, 'w': 380,
        'cols': [
            ('uuid', 'id', 'PK'),
            ('text', 'user_id', 'FK'),
            ('varchar(255)', 'name', ''),
            ('text', 'initial_prompt', ''),
            ('text', 'current_code', ''),
            ('uuid', 'current_version_id', 'FK'),
            ('boolean', 'is_published', ''),
            ('timestamptz', 'created_at', ''),
            ('timestamptz', 'updated_at', '')
        ]
    },
    'conversations': {
        'x': 600, 'y': 1480, 'w': 360,
        'cols': [
            ('uuid', 'id', 'PK'),
            ('uuid', 'project_id', 'FK'),
            ('role_enum', 'role', ''),
            ('text', 'content', ''),
            ('timestamptz', 'timestamp', '')
        ]
    },
    'versions': {
        'x': 1180, 'y': 1480, 'w': 370,
        'cols': [
            ('uuid', 'id', 'PK'),
            ('uuid', 'project_id', 'FK'),
            ('text', 'code', ''),
            ('varchar(255)', 'description', ''),
            ('timestamptz', 'timestamp', '')
        ]
    }
}

ROW_H = 34
HEADER_H = 46

def draw_table(name, info):
    theme = THEMES[name]
    x, y, w = info['x'], info['y'], info['w']
    cols = info['cols']
    h = HEADER_H + len(cols) * ROW_H
    info['h'] = h
    info['b'] = y + h  # bottom

    # Outer table border shadow & box
    shadow = FancyBboxPatch((x + 4, y + 4), w, h, boxstyle="round,pad=0,rounding_size=8",
                            facecolor='#000000', alpha=0.07, edgecolor='none', zorder=1)
    ax.add_patch(shadow)

    box = FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0,rounding_size=8",
                         facecolor='white', edgecolor=theme['border'], linewidth=2.0, zorder=2)
    ax.add_patch(box)

    # Header
    header = Rectangle((x, y), w, HEADER_H, facecolor=theme['header_bg'],
                       edgecolor=theme['border'], linewidth=1.5, zorder=3)
    ax.add_patch(header)

    ax.text(x + w / 2, y + HEADER_H / 2 + 2, name.upper(),
            ha='center', va='center', fontsize=12, fontweight='bold',
            color=theme['text'], family='sans-serif', zorder=4)

    # Columns
    cur_y = y + HEADER_H
    for i, (col_type, col_name, key_tag) in enumerate(cols):
        row_color = theme['row_bg'] if i % 2 == 0 else '#FFFFFF'
        row_rect = Rectangle((x, cur_y), w, ROW_H, facecolor=row_color,
                             edgecolor=theme['grid'], linewidth=0.6, zorder=3)
        ax.add_patch(row_rect)

        # Type (left)
        ax.text(x + 14, cur_y + ROW_H / 2, col_type,
                ha='left', va='center', fontsize=9.5, style='italic',
                color='#64748B', family='monospace', zorder=4)

        # Name (center-left)
        font_weight = 'bold' if key_tag != '' else 'normal'
        name_color = '#0F172A' if key_tag == '' else theme['text']
        ax.text(x + 130, cur_y + ROW_H / 2, col_name,
                ha='left', va='center', fontsize=10, fontweight=font_weight,
                color=name_color, family='sans-serif', zorder=4)

        # Key Tag (right)
        if key_tag:
            tag_color = '#DC2626' if 'PK' in key_tag else ('#2563EB' if 'FK' in key_tag else '#059669')
            # Tag pill
            tag_w = len(key_tag) * 11 + 12
            tag_x = x + w - tag_w - 10
            tag_box = FancyBboxPatch((tag_x, cur_y + 6), tag_w, ROW_H - 12,
                                     boxstyle="round,pad=0,rounding_size=4",
                                     facecolor='#F1F5F9', edgecolor=tag_color, linewidth=1.2, zorder=4)
            ax.add_patch(tag_box)
            ax.text(tag_x + tag_w / 2, cur_y + ROW_H / 2, key_tag,
                    ha='center', va='center', fontsize=8.5, fontweight='bold',
                    color=tag_color, family='monospace', zorder=5)

        cur_y += ROW_H

LINE_COLOR = '#334155'
LINE_WIDTH = 2.0

def draw_crows_foot(x, y, direct='bottom'):
    size = 14
    if direct == 'bottom':
        pts = [(x - size, y + size), (x, y), (x + size, y + size)]
        ax.plot([pts[0][0], pts[1][0]], [pts[0][1], pts[1][1]], color=LINE_COLOR, lw=LINE_WIDTH, zorder=5)
        ax.plot([pts[2][0], pts[1][0]], [pts[2][1], pts[1][1]], color=LINE_COLOR, lw=LINE_WIDTH, zorder=5)
        ax.plot([x - size, x + size], [y + size, y + size], color=LINE_COLOR, lw=LINE_WIDTH, zorder=5)
        return y + size
    elif direct == 'top':
        pts = [(x - size, y - size), (x, y), (x + size, y - size)]
        ax.plot([pts[0][0], pts[1][0]], [pts[0][1], pts[1][1]], color=LINE_COLOR, lw=LINE_WIDTH, zorder=5)
        ax.plot([pts[2][0], pts[1][0]], [pts[2][1], pts[1][1]], color=LINE_COLOR, lw=LINE_WIDTH, zorder=5)
        ax.plot([x - size, x + size], [y - size, y - size], color=LINE_COLOR, lw=LINE_WIDTH, zorder=5)
        return y - size
    elif direct == 'left':
        pts = [(x - size, y - size), (x, y), (x - size, y + size)]
        ax.plot([pts[0][0], pts[1][0]], [pts[0][1], pts[1][1]], color=LINE_COLOR, lw=LINE_WIDTH, zorder=5)
        ax.plot([pts[2][0], pts[1][0]], [pts[2][1], pts[1][1]], color=LINE_COLOR, lw=LINE_WIDTH, zorder=5)
        ax.plot([x - size, x - size], [y - size, y + size], color=LINE_COLOR, lw=LINE_WIDTH, zorder=5)
        return x - size
    elif direct == 'right':
        pts = [(x + size, y - size), (x, y), (x + size, y + size)]
        ax.plot([pts[0][0], pts[1][0]], [pts[0][1], pts[1][1]], color=LINE_COLOR, lw=LINE_WIDTH, zorder=5)
        ax.plot([pts[2][0], pts[1][0]], [pts[2][1], pts[1][1]], color=LINE_COLOR, lw=LINE_WIDTH, zorder=5)
        ax.plot([x + size, x + size], [y - size, y + size], color=LINE_COLOR, lw=LINE_WIDTH, zorder=5)
        return x + size

def draw_mandatory_one(x, y, orientation='vertical'):
    d = 10
    if orientation == 'vertical':
        ax.plot([x - d, x + d], [y - 4, y - 4], color=LINE_COLOR, lw=LINE_WIDTH, zorder=5)
        ax.plot([x - d, x + d], [y + 4, y + 4], color=LINE_COLOR, lw=LINE_WIDTH, zorder=5)
    else:
        ax.plot([x - 4, x - 4], [y - d, y + d], color=LINE_COLOR, lw=LINE_WIDTH, zorder=5)
        ax.plot([x + 4, x + 4], [y - d, y + d], color=LINE_COLOR, lw=LINE_WIDTH, zorder=5)

def draw_optional_one(x, y, orientation='vertical'):
    r = 6
    if orientation == 'vertical':
        c = Circle((x, y), r, facecolor='white', edgecolor=LINE_COLOR, lw=LINE_WIDTH, zorder=5)
        ax.add_patch(c)
        ax.plot([x - 10, x + 10], [y + 8, y + 8], color=LINE_COLOR, lw=LINE_WIDTH, zorder=5)
    else:
        c = Circle((x, y), r, facecolor='white', edgecolor=LINE_COLOR, lw=LINE_WIDTH, zorder=5)
        ax.add_patch(c)
        ax.plot([x + 8, x + 8], [y - 10, y + 10], color=LINE_COLOR, lw=LINE_WIDTH, zorder=5)

def label_relation(x, y, text):
    ax.text(x, y, text, ha='center', va='center', fontsize=9, fontweight='bold',
            color='#1E293B', family='sans-serif',
            bbox=dict(boxstyle='round,pad=0.25', facecolor='#F8FAFC', edgecolor='#CBD5E1', lw=1.0),
            zorder=6)

# Draw Title and Metadata Header
ax.text(900, 50, "AI WEB BUILDER — RELATIONAL DATABASE ER DIAGRAM (BCNF)",
        ha='center', va='center', fontsize=20, fontweight='heavy',
        color='#0F172A', family='sans-serif')
ax.text(900, 85, "Team T0080  |  Course: Advanced Programming / DBMS  |  Mentor: Satyaki  |  PostgreSQL 14+",
        ha='center', va='center', fontsize=12, fontweight='medium',
        color='#475569', family='sans-serif')

# Draw Tables
for name, info in TABLES.items():
    draw_table(name, info)

# ----------------- RELATIONSHIPS & CONNECTORS -----------------

# 1. USERS -> SESSIONS (1 to Many: user maintains sessions)
u_x_l = TABLES['users']['x']
u_y_s = TABLES['users']['y'] + 60
s_x_r = TABLES['sessions']['x'] + TABLES['sessions']['w']
s_y = TABLES['sessions']['y'] + 60
draw_mandatory_one(u_x_l - 12, u_y_s, 'horizontal')
end_x = draw_crows_foot(s_x_r, s_y, 'right')
ax.plot([u_x_l, end_x], [u_y_s, s_y], color=LINE_COLOR, lw=LINE_WIDTH, zorder=4)
label_relation((u_x_l + s_x_r) / 2, u_y_s - 14, "maintains (1:N)")

# 2. USERS -> ACCOUNTS (1 to Many: user authenticates via accounts)
u_x_r = TABLES['users']['x'] + TABLES['users']['w']
u_y_a = TABLES['users']['y'] + 60
a_x_l = TABLES['accounts']['x']
a_y = TABLES['accounts']['y'] + 60
draw_mandatory_one(u_x_r + 12, u_y_a, 'horizontal')
end_x = draw_crows_foot(a_x_l, a_y, 'left')
ax.plot([u_x_r, end_x], [u_y_a, a_y], color=LINE_COLOR, lw=LINE_WIDTH, zorder=4)
label_relation((u_x_r + a_x_l) / 2, u_y_a - 14, "authenticates (1:N)")

# 3. USERS -> WEBSITE_PROJECTS (1 to Many: user owns projects)
u_b = TABLES['users']['b']
u_x_mid = TABLES['users']['x'] + 180
p_t = TABLES['website_projects']['y']
p_x_mid = TABLES['website_projects']['x'] + 190
draw_mandatory_one(u_x_mid, u_b + 12, 'vertical')
end_y = draw_crows_foot(p_x_mid, p_t, 'top')
ax.plot([u_x_mid, p_x_mid], [u_b, end_y], color=LINE_COLOR, lw=LINE_WIDTH, zorder=4)
label_relation(p_x_mid + 45, (u_b + p_t) / 2, "owns (1:N)")

# 4. USERS -> TRANSACTIONS (1 to Many: user purchases credits)
u_y_tx = TABLES['users']['y'] + 220
tx_t = TABLES['transactions']['y']
tx_x_mid = TABLES['transactions']['x'] + 180
draw_mandatory_one(u_x_l - 12, u_y_tx, 'horizontal')
ax.plot([u_x_l, 590], [u_y_tx, u_y_tx], color=LINE_COLOR, lw=LINE_WIDTH, zorder=4)
ax.plot([590, 590], [u_y_tx, 1280], color=LINE_COLOR, lw=LINE_WIDTH, zorder=4)
ax.plot([590, tx_x_mid], [1280, 1280], color=LINE_COLOR, lw=LINE_WIDTH, zorder=4)
end_y = draw_crows_foot(tx_x_mid, tx_t, 'top')
ax.plot([tx_x_mid, tx_x_mid], [1280, end_y], color=LINE_COLOR, lw=LINE_WIDTH, zorder=4)
label_relation(590, 750, "purchases (1:N)")

# 5. SUBSCRIPTION_PLANS -> TRANSACTIONS (1 to Many: plan defines package)
sp_b = TABLES['subscription_plans']['b']
sp_x = TABLES['subscription_plans']['x'] + 100
tx_x_sp = TABLES['transactions']['x'] + 100
draw_mandatory_one(sp_x, sp_b + 12, 'vertical')
end_y = draw_crows_foot(tx_x_sp, tx_t, 'top')
ax.plot([sp_x, tx_x_sp], [sp_b, end_y], color=LINE_COLOR, lw=LINE_WIDTH, zorder=4)
label_relation(sp_x + 50, (sp_b + tx_t) / 2, "defines (1:N)")

# 6. WEBSITE_PROJECTS -> CONVERSATIONS (1 to Many: project logs conversation messages)
p_b = TABLES['website_projects']['b']
p_x_c = TABLES['website_projects']['x'] + 80
c_t = TABLES['conversations']['y']
c_x = TABLES['conversations']['x'] + 180
draw_mandatory_one(p_x_c, p_b + 12, 'vertical')
ax.plot([p_x_c, p_x_c], [p_b, 1400], color=LINE_COLOR, lw=LINE_WIDTH, zorder=4)
ax.plot([p_x_c, c_x], [1400, 1400], color=LINE_COLOR, lw=LINE_WIDTH, zorder=4)
end_y = draw_crows_foot(c_x, c_t, 'top')
ax.plot([c_x, c_x], [1400, end_y], color=LINE_COLOR, lw=LINE_WIDTH, zorder=4)
label_relation(c_x - 45, 1425, "records (1:N)")

# 7. WEBSITE_PROJECTS -> VERSIONS (1 to Many: project creates code versions)
p_x_v = TABLES['website_projects']['x'] + 300
v_t = TABLES['versions']['y']
v_x = TABLES['versions']['x'] + 180
draw_mandatory_one(p_x_v, p_b + 12, 'vertical')
ax.plot([p_x_v, p_x_v], [p_b, 1400], color=LINE_COLOR, lw=LINE_WIDTH, zorder=4)
ax.plot([p_x_v, v_x], [1400, 1400], color=LINE_COLOR, lw=LINE_WIDTH, zorder=4)
end_y = draw_crows_foot(v_x, v_t, 'top')
ax.plot([v_x, v_x], [1400, end_y], color=LINE_COLOR, lw=LINE_WIDTH, zorder=4)
label_relation(v_x + 45, 1425, "revises into (1:N)")

# 8. WEBSITE_PROJECTS -> VERSIONS (current_version_id, 1 to 1 optional link)
p_r_x = TABLES['website_projects']['x'] + TABLES['website_projects']['w']
p_r_y = TABLES['website_projects']['y'] + 140
v_r_x = TABLES['versions']['x'] + TABLES['versions']['w']
v_r_y = TABLES['versions']['y'] + 60
draw_optional_one(p_r_x + 12, p_r_y, 'horizontal')
ax.plot([p_r_x, 1650], [p_r_y, p_r_y], color='#6366F1', lw=LINE_WIDTH, ls='--', zorder=4)
ax.plot([1650, 1650], [p_r_y, v_r_y], color='#6366F1', lw=LINE_WIDTH, ls='--', zorder=4)
draw_mandatory_one(1650 - 12, v_r_y, 'horizontal')
ax.plot([1650, v_r_x], [v_r_y, v_r_y], color='#6366F1', lw=LINE_WIDTH, ls='--', zorder=4)
label_relation(1650, (p_r_y + v_r_y) / 2, "active_version (0..1 : 1)")

# Legend box at bottom left
leg_x, leg_y = 180, 1850
leg_w, leg_h = 360, 260
leg_box = FancyBboxPatch((leg_x, leg_y), leg_w, leg_h, boxstyle="round,pad=0,rounding_size=6",
                         facecolor='#F8FAFC', edgecolor='#94A3B8', linewidth=1.2, zorder=2)
ax.add_patch(leg_box)
ax.text(leg_x + 18, leg_y + 30, "NOTATION KEY (CROW'S FOOT)", fontsize=11, fontweight='bold', color='#0F172A')

# Key items
ax.text(leg_x + 18, leg_y + 70, "PK  = Primary Key (Entity Identifier)", fontsize=9.5, fontweight='bold', color='#DC2626')
ax.text(leg_x + 18, leg_y + 100, "FK  = Foreign Key (Referential Integrity)", fontsize=9.5, fontweight='bold', color='#2563EB')
ax.text(leg_x + 18, leg_y + 130, "UK  = Unique Key Constraint", fontsize=9.5, fontweight='bold', color='#059669')
ax.text(leg_x + 18, leg_y + 160, "||  = Exactly One (Mandatory)", fontsize=9.5, color='#334155')
ax.text(leg_x + 18, leg_y + 190, "-<- = Zero or Many (Optional Many)", fontsize=9.5, color='#334155')
ax.text(leg_x + 18, leg_y + 220, "--- = 1:N Relationship / - - = Optional Pointer", fontsize=9.5, color='#6366F1')

# Save high-res PNG image
output_path = os.path.join(os.path.dirname(__file__), '02_er_diagram.png')
plt.savefig(output_path, dpi=200, bbox_inches='tight', facecolor='white', edgecolor='none')
print(f"ER diagram successfully created at {output_path}")
