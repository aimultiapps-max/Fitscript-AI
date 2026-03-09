const docConfig = {
  en: {
    guide: {
      file: "./docs/usage_guide_fitscript_ai_en.md",
      title: "Usage Guide",
      desc: "How to use FitScript AI safely and effectively.",
    },
    privacy: {
      file: "./docs/privacy_policy_fitscript_ai.md",
      title: "Privacy Policy",
      desc: "How we collect, process, and protect your data.",
    },
    terms: {
      file: "./docs/terms_and_conditions_fitscript_ai.md",
      title: "Terms and Conditions",
      desc: "Rules and terms for using FitScript AI.",
    },
  },
  id: {
    guide: {
      file: "./docs/usage_guide_fitscript_ai.md",
      title: "Panduan Penggunaan",
      desc: "Cara menggunakan FitScript AI dengan aman dan efektif.",
    },
    privacy: {
      file: "./docs/privacy_policy_fitscript_ai_id.md",
      title: "Kebijakan Privasi",
      desc: "Cara kami mengumpulkan, memproses, dan melindungi data Anda.",
    },
    terms: {
      file: "./docs/terms_and_conditions_fitscript_ai_id.md",
      title: "Syarat dan Ketentuan",
      desc: "Aturan dan ketentuan penggunaan FitScript AI.",
    },
  },
};

const guideContent = document.getElementById("guide-content");
const privacyContent = document.getElementById("privacy-content");
const termsContent = document.getElementById("terms-content");

const guideTitle = document.getElementById("guide-title");
const privacyTitle = document.getElementById("privacy-title");
const termsTitle = document.getElementById("terms-title");

const guideDesc = document.getElementById("guide-desc");
const privacyDesc = document.getElementById("privacy-desc");
const termsDesc = document.getElementById("terms-desc");

const langEn = document.getElementById("lang-en");
const langId = document.getElementById("lang-id");

document.getElementById("year").textContent = new Date().getFullYear();

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

async function fetchText(path) {
  const response = await fetch(path);
  if (!response.ok) {
    throw new Error(`Failed to fetch ${path}`);
  }
  return response.text();
}

async function loadLanguage(lang) {
  const conf = docConfig[lang] || docConfig.en;

  guideTitle.textContent = conf.guide.title;
  privacyTitle.textContent = conf.privacy.title;
  termsTitle.textContent = conf.terms.title;

  guideDesc.textContent = conf.guide.desc;
  privacyDesc.textContent = conf.privacy.desc;
  termsDesc.textContent = conf.terms.desc;

  guideContent.textContent = "Loading...";
  privacyContent.textContent = "Loading...";
  termsContent.textContent = "Loading...";

  try {
    const [guide, privacy, terms] = await Promise.all([fetchText(conf.guide.file), fetchText(conf.privacy.file), fetchText(conf.terms.file)]);

    guideContent.innerHTML = markdownToHtml(guide);
    privacyContent.innerHTML = markdownToHtml(privacy);
    termsContent.innerHTML = markdownToHtml(terms);
  } catch (error) {
    const message = `Unable to load content. ${error.message}`;
    guideContent.innerHTML = `<p>${message}</p>`;
    privacyContent.innerHTML = `<p>${message}</p>`;
    termsContent.innerHTML = `<p>${message}</p>`;
  }
}

langEn.addEventListener("click", () => {
  langEn.classList.add("active");
  langId.classList.remove("active");
  loadLanguage("en");
});

langId.addEventListener("click", () => {
  langId.classList.add("active");
  langEn.classList.remove("active");
  loadLanguage("id");
});

loadLanguage("en");
