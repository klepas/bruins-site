// Moves focus to the target of a link marked data-skip-link when the link is
// followed: "Skip to content" and "Back to top". Safari scrolls to a target
// that can't take focus but leaves focus behind, so after Return, VoiceOver
// stays on the link and reads on from there. Without this script, VO+Space
// still works, and Tab still carries on from the target.
//
// After GOV.UK Frontend's SkipLink and setFocus (MIT, Crown Copyright):
// https://github.com/alphagov/govuk-frontend/blob/main/packages/govuk-frontend/src/govuk/common/index.mjs
// The target has tabindex="-1" only until focus leaves it, so a click in the
// page never focuses it. Meanwhile its class hides the focus ring, as the
// reader can't operate it.
for (const link of document.querySelectorAll("a[data-skip-link]")) {
  const target = document.getElementById(link.hash.slice(1));
  if (!target) continue;

  link.addEventListener("click", () => {
    const hadTabindex = target.hasAttribute("tabindex");
    if (!hadTabindex) target.setAttribute("tabindex", "-1");
    target.classList.add("skip-link-target");

    target.addEventListener("focus", () => {
      target.addEventListener("blur", () => {
        target.classList.remove("skip-link-target");
        if (!hadTabindex) target.removeAttribute("tabindex");
      }, { once: true });
    }, { once: true });

    target.focus();
  });
}
