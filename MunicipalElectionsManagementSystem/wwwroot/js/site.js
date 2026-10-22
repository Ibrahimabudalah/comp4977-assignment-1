// Dark mode toggle. The initial theme is set by an inline script in _Layout.cshtml.
(function () {
    const root = document.documentElement;
    const toggle = document.getElementById("theme-toggle");

    function updateLabel() {
        toggle.textContent = root.getAttribute("data-bs-theme") === "dark"
            ? "Light mode"
            : "Dark mode";
    }

    toggle.addEventListener("click", function () {
        const theme = root.getAttribute("data-bs-theme") === "dark" ? "light" : "dark";
        root.setAttribute("data-bs-theme", theme);
        localStorage.setItem("theme", theme);
        updateLabel();
    });

    // Always print in light mode so text stays readable on paper.
    let themeBeforePrint;

    window.addEventListener("beforeprint", function () {
        themeBeforePrint = root.getAttribute("data-bs-theme");
        root.setAttribute("data-bs-theme", "light");
    });

    window.addEventListener("afterprint", function () {
        root.setAttribute("data-bs-theme", themeBeforePrint);
    });

    updateLabel();
})();
