(function () {
  function initializeSidebarTooltips() {
    document.querySelectorAll("button.collapse-toggle").forEach(function (button) {
      const label = "Seitenleiste ein/ausklappen";
      button.removeAttribute("title");
      button.setAttribute("aria-label", label);
      const tooltip = bootstrap.Tooltip.getOrCreateInstance(button, {
        title: label,
        placement: "right",
        fallbackPlacements: [],
        container: "body",
        trigger: "hover focus"
      });
      button.addEventListener("click", function () {
        tooltip.hide();
      });
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initializeSidebarTooltips);
  } else {
    initializeSidebarTooltips();
  }
})();
