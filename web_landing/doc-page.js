const pages = {
  guide: {
    en: {
      file: "./docs/usage_guide_fitscript_ai_en.md",
      title: "Usage Guide",
      desc: "How to use FitScript AI safely and effectively.",
    },
    id: {
      file: "./docs/usage_guide_fitscript_ai.md",
      title: "Panduan Penggunaan",
      desc: "Cara menggunakan FitScript AI dengan aman dan efektif.",
    },
  },
  privacy: {
    en: {
      file: "./docs/privacy_policy_fitscript_ai.md",
      title: "Privacy Policy",
      desc: "How we collect, process, and protect your data.",
    },
    id: {
      file: "./docs/privacy_policy_fitscript_ai_id.md",
      title: "Kebijakan Privasi",
      desc: "Cara kami mengumpulkan, memproses, dan melindungi data Anda.",
    },
  },
  terms: {
    en: {
      file: "./docs/terms_and_conditions_fitscript_ai.md",
      title: "Terms and Conditions",
      desc: "Rules and terms for using FitScript AI.",
    },
    id: {
      file: "./docs/terms_and_conditions_fitscript_ai_id.md",
      title: "Syarat dan Ketentuan",
      desc: "Aturan dan ketentuan penggunaan FitScript AI.",
    },
  },
};

const pageKey = document.body.dataset.page;
const pageConfig = pages[pageKey] || pages.guide;

const title = document.getElementById("doc-title");
const desc = document.getElementById("doc-desc");
const content = document.getElementById("doc-content");
const langEn = document.getElementById("lang-en");
const langId = document.getElementById("lang-id");
const year = document.getElementById("year");

year.textContent = new Date().getFullYear();

function markdownToHtml(markdown) {
  const lines = markdown.replace(/\r\n/g, "\n").split("\n");
  let html = "";
  let inList = false;

  const closeList = () => {
    if (inList) {
      html += "</ul>";
      inList = false;
    }
  };

  for (const rawLine of lines) {
    const line = rawLine.trim();

    if (!line) {
      closeList();
      continue;
    }

    if (line === "---") {
      closeList();
      html += "<hr />";
      continue;
    }

    if (line.startsWith("### ")) {
      closeList();
      html += `<h3>${line.slice(4)}</h3>`;
      continue;
    }

    if (line.startsWith("## ")) {
      closeList();
      html += `<h2>${line.slice(3)}</h2>`;
      continue;
    }

    if (line.startsWith("# ")) {
      closeList();
      html += `<h1>${line.slice(2)}</h1>`;
      continue;
    }

    if (line.startsWith("- ")) {
      if (!inList) {
        html += "<ul>";
        inList = true;
      }
      html += `<li>${line.slice(2)}</li>`;
      continue;
    }

    closeList();
    html += `<p>${line}</p>`;
  }

  closeList();

  return html.replace(/\*\*(.*?)\*\*/g, "<strong>$1</strong>").replace(/\*(.*?)\*/g, "<em>$1</em>");
}

async function fetchDoc(path) {
  const response = await fetch(path);
  if (!response.ok) throw new Error(`Failed to fetch ${path}`);
  return response.text();
}

async function load(lang) {
  const conf = pageConfig[lang] || pageConfig.en;
  title.textContent = conf.title;
  desc.textContent = conf.desc;
  content.textContent = "Loading...";
  try {
    const markdown = await fetchDoc(conf.file);
    content.innerHTML = markdownToHtml(markdown);
  } catch (error) {
    content.innerHTML = `<p>Unable to load content. ${error.message}</p>`;
  }
}

langEn.addEventListener("click", () => {
  langEn.classList.add("active");
  langId.classList.remove("active");
  load("en");
});

langId.addEventListener("click", () => {
  langId.classList.add("active");
  langEn.classList.remove("active");
  load("id");
});

load("en");
