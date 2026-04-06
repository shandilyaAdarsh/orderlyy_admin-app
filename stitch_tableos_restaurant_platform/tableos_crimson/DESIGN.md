# The Design System: Precision Hospitality

## 1. Overview & Creative North Star: "The Culinary Architect"
This design system is built for the high-stakes, high-density world of restaurant intelligence. It moves beyond generic SaaS templates to embrace **The Culinary Architect**—a North Star that balances the razor-sharp precision of financial tools (Razorpay/Zerodha) with the warmth and prestige of fine dining.

We achieve a "Modern Indian SaaS" aesthetic by combining high-density information layouts with expansive white space and intentional, asymmetric accents. The experience should feel like a well-organized commercial kitchen: everything has its place, the tools are professional-grade, and the atmosphere is one of calm, controlled authority. We break the grid through overlapping status layers and a strict reliance on tonal depth rather than structural rigidity.

---

## 2. Colors & Surface Philosophy
The palette is rooted in a high-contrast "Pure White & Crimson" foundation, accented by slate neutrals that provide a professional, sober backdrop for data.

### Surface Hierarchy & Nesting
To achieve a premium feel, we abandon the "flat box" approach. We treat the UI as a series of physical layers.
*   **Base Layer:** `surface` (#F8FAFB) – Used for the main application background.
*   **The Paper Layer:** `surface_container_lowest` (#FFFFFF) – Used for primary content cards and work areas.
*   **The Inset Layer:** `surface_container_low` (#F2F4F5) – Used for secondary sidebars or nested data tables to create "recessed" depth.

### The "No-Line" Rule
**Explicit Instruction:** Prohibit the use of 1px solid borders for sectioning. Boundaries must be defined through background shifts. Instead of drawing a line between a sidebar and a main view, change the sidebar to `surface_container_low`. This creates a sophisticated, "un-templated" look that feels integrated and expansive.

### The "Glass & Gradient" Rule
For floating elements (modals, dropdowns), utilize Glassmorphism. Use `surface` colors at 80% opacity with a `20px` backdrop blur. For primary CTAs, apply a subtle linear gradient from `primary` (#9D0518) to `primary_container` (#C0272D) at a 135-degree angle to give the Crimson "soul" and dimension.

---

## 3. Typography: The Editorial Scale
We use **Inter** for its neutral, high-legibility character, paired with **JetBrains Mono** for technical data strings (Order IDs, Table Numbers, P&L Metrics).

*   **Display/Headline:** Use `headline-lg` (Inter Bold, 32px) for dashboard overviews. The high contrast between the Bold weight and the slate-gray `secondary` text (#475569) creates an authoritative hierarchy.
*   **Sub-headers:** `title-md` (Inter Semibold, 18px) for card titles, providing a clear anchor for dense data.
*   **Technical IDs:** `label-md` (JetBrains Mono, 12px) with a `0.05em` letter-spacing. This monospace intervention signals to the user that they are looking at "System Data" versus "Human Content."
*   **Body:** `body-md` (Inter Regular, 14px) is our workhorse. Ensure a line height of `1.6` to maintain "Zero Clutter" even in high-density views.

---

## 4. Elevation & Depth: Tonal Layering
We move away from traditional shadows to a system of **Tonal Layering**. 

*   **The Layering Principle:** A `surface_container_lowest` (#FFFFFF) card sitting on a `surface` (#F8FAFB) background provides enough natural lift. No shadow is required for static cards.
*   **Ambient Shadows:** For interactive "floating" states, use a "Crimson-Tinted Shadow": 
    *   `box-shadow: 0 12px 32px -8px rgba(157, 5, 24, 0.08);` 
    *   This shadow is extra-diffused and low-opacity, mimicking natural light filtered through the brand's primary color.
*   **The Ghost Border:** If a boundary is required for accessibility in forms, use the `outline_variant` at 20% opacity. Never use 100% opaque borders.
*   **Active States:** Apply the **Signature Red Strike**—a 3px left-aligned border using `primary_container` (#C0272D) coupled with an 8% `primary` tint background to denote active navigation or selected table rows.

---

## 5. Components: High-Density Primitives

### Buttons
*   **Primary:** 52px height, 8px (`md`) radius. Background: `primary_container`. Text: `on_primary` (White, Semibold). 
*   **Secondary:** 52px height. Background: `primary` at 8% opacity. Text: `primary_container`. No border.
*   **Tertiary:** Ghost style. Text: `secondary`. On hover, shift background to `surface_container_high`.

### Cards & Data Lists
*   **Rules:** Forbid the use of horizontal divider lines. Use `16px` or `24px` of vertical white space to separate list items.
*   **Radius:** Strict `12px` (referencing `md` to `lg` scale).
*   **Status Badges:** Pill-shaped (`full` radius). Use a 6px solid dot of the status color (e.g., `error` for 'Delayed') next to `label-sm` text. The badge background should be a 10% tint of the status color.

### Input Fields
*   High-density focus. Label sits above the field in `label-md` (Slate Gray). 
*   Field background: `surface_container_lowest`. 
*   Bottom-only border: A 2px `surface_container_high` border that transforms into `primary_container` on focus. This mimics modern financial dashboards.

### Specialized Component: The "Intelligence Rail"
A vertical, high-density sidebar for real-time kitchen metrics. Use `surface_container_highest` background with `JetBrains Mono` for all numerical values to emphasize the "Intelligence Platform" aspect.

---

## 6. Do's and Don'ts

### Do
*   **Do** use 8% Crimson tints (`primary_fixed_dim`) for hover states on rows.
*   **Do** prioritize vertical rhythm over horizontal lines.
*   **Do** use `JetBrains Mono` for any number that can be calculated (Price, Time, ID).
*   **Do** embrace asymmetry—allow cards to have different heights in a masonry-style dashboard to feel "Editorial."

### Don't
*   **Don't** use 1px solid `#E2E8F0` borders unless it is a complex data table that requires strict containment.
*   **Don't** use standard "Drop Shadows" (Black/Grey). Always tint shadows with the `on_surface` or `primary` hue.
*   **Don't** use icons as purely decorative elements. Every icon must be functional and follow the `secondary` color token.
*   **Don't** clutter the UI. If a screen feels "busy," increase the `surface` padding rather than adding more containers.