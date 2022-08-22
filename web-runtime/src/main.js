console.log("Hello world");

function runKatecBlockMathIds(id_set) {
    for (const id of id_set) {
        const element = document.getElementById(id);
        katex.render(element.textContent, element, {displayMode: true});
    }
}
function runKatecInlineMathIds(id_set) {
    for (const id of id_set) {
        const element = document.getElementById(id);
        katex.render(element.textContent, element, {displayMode: false});
    }
}

window.onload = () => {
    let darkmode = window.matchMedia('(prefers-color-scheme: dark)').matches;
    if (darkmode) {
        console.log("init darkmode")
    } else {
        console.log("init lightmode")
    }
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', event => {
        if (event.matches) {
            //dark mode
            console.log("Changed to dark mode");
        } else {
            //light mode
            console.log("Changed to light mode");
        }
    })
};
