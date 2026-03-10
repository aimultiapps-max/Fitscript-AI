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

const landingCopy = {
  en: {
    hero: {
      title: "FitScript AI",
      subtitle: "Official app information and legal documents",
    },
    about: {
      label: "About App",
      title: "Why people choose FitScript AI",
      desc: "AI-powered health companion built for clarity and privacy.",
      items: ["Real-time lab result scanning with contextual explanations.", "Trend dashboards to understand long-term health signals.", "Secure-by-design cloud with anonymous onboarding path."],
    },
    support: {
      label: "Support Information",
      title: "Need help or have compliance questions?",
      desc: "We respond fast across official channels.",
      items: ['<strong>Email</strong>: <a href="mailto:support@fitscript.ai">support@fitscript.ai</a>', "Response window: under 24 hours on business days.", "Data deletion / portability requests processed within 7 business days."],
      cta: {
        text: "Contact Support",
        href: "mailto:support@fitscript.ai",
      },
    },
    marketing: {
      label: "Marketing Information",
      title: "Brand, assets, and press-ready copy",
      desc: "Everything you need to feature FitScript AI accurately.",
      items: ["One-liner, pitch paragraph, and storefront keywords.", "Downloadable icon pack, hero renders, screenshot frames.", "Medical disclaimer template for promotional materials."],
      cta: {
        text: "Request media kit →",
        href: "mailto:support@fitscript.ai?subject=FitScript%20AI%20media%20kit",
      },
    },
  },
  id: {
    hero: {
      title: "FitScript AI",
      subtitle: "Informasi resmi aplikasi dan dokumen hukum",
    },
    about: {
      label: "Tentang Aplikasi",
      title: "Kenapa banyak pengguna memilih FitScript AI",
      desc: "Pendamping kesehatan berbasis AI yang fokus pada kejelasan dan privasi.",
      items: ["Pemindaian hasil lab instan dengan penjelasan kontekstual.", "Panel tren untuk membaca sinyal kesehatan jangka panjang.", "Cloud aman dengan opsi mulai anonim tanpa akun."],
    },
    support: {
      label: "Informasi Dukungan",
      title: "Butuh bantuan atau dokumen kepatuhan?",
      desc: "Tim kami responsif melalui kanal resmi.",
      items: ['<strong>Email</strong>: <a href="mailto:support@fitscript.ai">support@fitscript.ai</a>', "Waktu respons: maksimal 24 jam di hari kerja.", "Permintaan penghapusan / portabilitas diproses maksimal 7 hari kerja."],
      cta: {
        text: "Hubungi Dukungan",
        href: "mailto:support@fitscript.ai",
      },
    },
    marketing: {
      label: "Informasi Marketing",
      title: "Brand, aset, dan materi pers",
      desc: "Semua kebutuhan untuk menampilkan FitScript AI secara akurat.",
      items: ["Kalimat promosi singkat, paragraf pitch, dan kata kunci store.", "Unduhan paket ikon, render hero, dan bingkai screenshot.", "Template disclaimer medis untuk materi promosi."],
      cta: {
        text: "Minta media kit →",
        href: "mailto:support@fitscript.ai?subject=Permintaan%20media%20kit%20FitScript%20AI",
      },
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

const aboutLabel = document.getElementById("about-label");
const aboutTitle = document.getElementById("about-title");
const aboutDesc = document.getElementById("about-desc");
const aboutList = document.getElementById("about-list");

const supportLabel = document.getElementById("support-label");
const supportTitle = document.getElementById("support-title");
const supportDesc = document.getElementById("support-desc");
const supportList = document.getElementById("support-list");
const supportCta = document.getElementById("support-cta");

const marketingLabel = document.getElementById("marketing-label");
const marketingTitle = document.getElementById("marketing-title");
const marketingDesc = document.getElementById("marketing-desc");
const marketingList = document.getElementById("marketing-list");
const marketingCta = document.getElementById("marketing-cta");

const heroTitle = document.getElementById("hero-title");
const heroSubtitle = document.getElementById("hero-subtitle");

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
  applyLandingCopy(lang);

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

function applyLandingCopy(lang) {
  const copy = landingCopy[lang] || landingCopy.en;
  const fillList = (ul, items) => {
    ul.innerHTML = "";
    items.forEach((item) => {
      const li = document.createElement("li");
      li.innerHTML = item;
      ul.appendChild(li);
    });
  };

  aboutLabel.textContent = copy.about.label;
  aboutTitle.textContent = copy.about.title;
  aboutDesc.textContent = copy.about.desc;
  fillList(aboutList, copy.about.items);

  heroTitle.textContent = copy.hero.title;
  heroSubtitle.textContent = copy.hero.subtitle;

  supportLabel.textContent = copy.support.label;
  supportTitle.textContent = copy.support.title;
  supportDesc.textContent = copy.support.desc;
  fillList(supportList, copy.support.items);
  supportCta.textContent = copy.support.cta.text;
  supportCta.onclick = () => {
    window.location.href = copy.support.cta.href;
  };

  marketingLabel.textContent = copy.marketing.label;
  marketingTitle.textContent = copy.marketing.title;
  marketingDesc.textContent = copy.marketing.desc;
  fillList(marketingList, copy.marketing.items);
  marketingCta.textContent = copy.marketing.cta.text;
  marketingCta.setAttribute("href", copy.marketing.cta.href);
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
