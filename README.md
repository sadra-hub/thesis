# Data-Driven Decision Support

> A lightweight web portal for presenting thesis assets through linked descriptive and analytical models.

## Project Snapshot
- **Landing + Router:** `index.html` hosts a single-page experience with a fullscreen menu that routes between the landing, Documents, Models, and Demo views.
- **Document Library:** Everything under `docs/` becomes a card with inline preview support for PDFs and text-based assets.
- **Model Browser:** Files in `models/` are listed with the same preview pattern, making it easy to share SysML artifacts.
- **LLM Demo Chat:** A minimal client that sends GET requests to the configured webhook to showcase conversational insights.

## Quick Start
1. Serve the repository locally (any static server works). Example:
   ```bash
   python3 -m http.server 8000
   ```
2. Navigate to `http://localhost:8000/index.html` and use the menu to explore Documents, Models, or the Demo chat.
3. Update the placeholder GitHub information (see **Configuration**) so the live lists pull from the correct repository.

## Configuration
- In `index.html`, search for the `CONFIG` block and set:
  - `GITHUB_USER` – your account or organization.
  - `GITHUB_REPO` – the repository name that hosts `docs/` and `models/`.
  - `BRANCH` – the default branch to fetch raw files from.
- Ensure `docs/` and `models/` exist in that remote repository; the GitHub API fetches directory contents live.
- Adjust `WEBHOOK` if the LLM demo endpoint changes; the UI expects a simple text or JSON response.

## Repository Layout
| Path | Description |
| --- | --- |
| `index.html` | Monochrome SPA with routing, GitHub integration helpers, and the chat demo client. |
| `docs/` | Thesis documents surfaced in the Documents view. |
| `models/` | SysML or related analytical assets rendered in the Models view. |
| `README.md` | Project overview, configuration notes, and usage guidance (this file). |

## Working With Content
- Drop additional files into `docs/` or `models/`; they appear automatically the next time the page loads.
- Binary previews (PDF, PNG, JPG, SVG) open inline via `<iframe>` or `<img>`. Text formats render inside `<pre>`.
- For large PDFs, consider optimizing file size to keep load times reasonable when hosted on GitHub Pages.

## Deployment Notes
- The site is static—deploy to GitHub Pages, Netlify, or any S3-compatible host. No build step required.
- When using GitHub Pages, the GitHub API rate limits unauthenticated calls; add a simple proxy or Personal Access Token if the page is public and traffic is high.
- Keep the webhook endpoint secured. For production demos, add basic auth or rotate the endpoint URL regularly.

## Next Steps
- [ ] Replace placeholder GitHub constants with live values.
- [ ] Populate `docs/` and `models/` with the latest thesis artifacts.
- [ ] Style or theme adjustments can be made within the `<style>` block in `index.html`.

