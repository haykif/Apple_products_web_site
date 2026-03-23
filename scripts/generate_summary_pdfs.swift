import Foundation
import AppKit

struct Section {
    let title: String
    let paragraphs: [String]
}

struct Summary {
    let code: String
    let languageName: String
    let title: String
    let subtitle: String
    let leftSections: [Section]
    let rightSections: [Section]
}

struct Theme {
    let titleFont: NSFont
    let subtitleFont: NSFont
    let sectionFont: NSFont
    let bodyFont: NSFont
    let noteFont: NSFont
    let titleColor = NSColor(calibratedRed: 0.09, green: 0.10, blue: 0.12, alpha: 1)
    let subtitleColor = NSColor(calibratedRed: 0.35, green: 0.37, blue: 0.42, alpha: 1)
    let sectionColor = NSColor(calibratedRed: 0.17, green: 0.29, blue: 0.49, alpha: 1)
    let bodyColor = NSColor(calibratedRed: 0.11, green: 0.12, blue: 0.15, alpha: 1)
    let lineColor = NSColor(calibratedRed: 0.84, green: 0.87, blue: 0.91, alpha: 1)
}

let outputDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("output/pdf", isDirectory: true)

try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

func makeTheme(bodySize: CGFloat) -> Theme {
    Theme(
        titleFont: .systemFont(ofSize: bodySize + 9.0, weight: .bold),
        subtitleFont: .systemFont(ofSize: bodySize + 0.8, weight: .regular),
        sectionFont: .systemFont(ofSize: bodySize + 1.9, weight: .semibold),
        bodyFont: .systemFont(ofSize: bodySize, weight: .regular),
        noteFont: .systemFont(ofSize: max(bodySize - 1.2, 6.4), weight: .regular)
    )
}

func paragraphStyle(lineSpacing: CGFloat = 1.8, paragraphSpacing: CGFloat = 3.5) -> NSMutableParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.lineBreakMode = .byWordWrapping
    style.lineSpacing = lineSpacing
    style.paragraphSpacing = paragraphSpacing
    return style
}

func attributed(_ text: String, font: NSFont, color: NSColor, lineSpacing: CGFloat = 1.8, paragraphSpacing: CGFloat = 3.5) -> NSAttributedString {
    NSAttributedString(
        string: text,
        attributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle(lineSpacing: lineSpacing, paragraphSpacing: paragraphSpacing)
        ]
    )
}

func textHeight(_ text: NSAttributedString, width: CGFloat) -> CGFloat {
    ceil(
        text.boundingRect(
            with: NSSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        ).height
    )
}

func renderText(_ text: NSAttributedString, x: CGFloat, y: CGFloat, width: CGFloat, pageHeight: CGFloat) -> CGFloat {
    let height = textHeight(text, width: width)
    let rect = NSRect(x: x, y: pageHeight - y - height, width: width, height: height)
    text.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading])
    return height
}

func sectionHeight(_ section: Section, width: CGFloat, theme: Theme) -> CGFloat {
    var total: CGFloat = 0
    total += textHeight(attributed(section.title, font: theme.sectionFont, color: theme.sectionColor, lineSpacing: 0.8, paragraphSpacing: 0), width: width)
    total += 10
    for paragraph in section.paragraphs {
        total += textHeight(attributed(paragraph, font: theme.bodyFont, color: theme.bodyColor), width: width)
        total += 5
    }
    total += 7
    return total
}

func renderSection(_ section: Section, x: CGFloat, y: CGFloat, width: CGFloat, pageHeight: CGFloat, theme: Theme) -> CGFloat {
    var cursor = y
    let heading = attributed(section.title, font: theme.sectionFont, color: theme.sectionColor, lineSpacing: 0.8, paragraphSpacing: 0)
    cursor += renderText(heading, x: x, y: cursor, width: width, pageHeight: pageHeight)
    cursor += 4

    theme.lineColor.setFill()
    NSBezierPath(rect: NSRect(x: x, y: pageHeight - cursor - 1, width: width, height: 1)).fill()
    cursor += 6

    for paragraph in section.paragraphs {
        let attr = attributed(paragraph, font: theme.bodyFont, color: theme.bodyColor)
        cursor += renderText(attr, x: x, y: cursor, width: width, pageHeight: pageHeight)
        cursor += 5
    }

    return cursor + 6
}

func fittingBodySize(for summary: Summary, columnWidth: CGFloat, availableHeight: CGFloat) -> CGFloat {
    let candidates: [CGFloat] = [8.9, 8.7, 8.5, 8.3, 8.1, 7.9]
    for size in candidates {
        let theme = makeTheme(bodySize: size)
        let leftHeight = summary.leftSections.reduce(CGFloat.zero) { $0 + sectionHeight($1, width: columnWidth, theme: theme) }
        let rightHeight = summary.rightSections.reduce(CGFloat.zero) { $0 + sectionHeight($1, width: columnWidth, theme: theme) }
        if max(leftHeight, rightHeight) <= availableHeight {
            return size
        }
    }
    return candidates.last ?? 7.9
}

let evidenceNote = "Repo evidence: README.md, regions.html, index.html, index_us.html, index_de.html, index_es.html, index_it.html, index_tr.html, index_jp.html, index_cn.html, styles/styles.css, styles/styles_of_regions.css, styles/styles_of_kiz.css, images/."

let summaries: [Summary] = [
    Summary(
        code: "fr",
        languageName: "French",
        title: "Ma Collection Apple",
        subtitle: "Résumé de l'application - Français - Fichier localisé : index.html",
        leftSections: [
            Section(
                title: "Ce que c'est",
                paragraphs: [
                    "Site vitrine statique, sur une seule page, qui présente une collection personnelle de produits Apple. Chaque page localisée reprend la même structure et relie les cartes produit vers des pages Apple ou Support Apple."
                ]
            ),
            Section(
                title: "Pour qui",
                paragraphs: [
                    "Persona principal : un collectionneur Apple qui veut exposer sa collection en ligne à des visiteurs ou amis."
                ]
            ),
            Section(
                title: "Ce que l'app fait",
                paragraphs: [
                    "- Propose un sélecteur de pays/langue via regions.html.",
                    "- Affiche 6 catégories ancrées : Mac, iPad, iPhone, Watch, AirPods, TV et Maison.",
                    "- Présente des cartes produit avec image, nom et parfois description via l'attribut title.",
                    "- Ouvre des liens Apple Store ou Support Apple localisés dans un nouvel onglet.",
                    "- Sépare les appareils et leurs accessoires à l'intérieur de chaque catégorie.",
                    "- Réutilise une même mise en page responsive en grille et cartes sur toutes les langues.",
                    "- Ajoute un lien retour vers le sélecteur de région et un popup image déclenché depuis le copyright."
                ]
            )
        ],
        rightSections: [
            Section(
                title: "Fonctionnement",
                paragraphs: [
                    "- Points d'entrée : regions.html redirige vers 8 pages HTML localisées.",
                    "- Présentation : styles/styles.css gère les pages produit ; styles/styles_of_regions.css gère le sélecteur ; styles/styles_of_kiz.css gère la fenêtre popup.",
                    "- Données : les listes produit, textes et URL Apple sont codées en dur directement dans chaque fichier HTML.",
                    "- Flux : l'utilisateur choisit une région, navigue par ancres dans la page, puis ouvre des liens externes depuis les cartes produit.",
                    "- Services/backend/API : Not found in repo."
                ]
            ),
            Section(
                title: "Démarrage",
                paragraphs: [
                    "- Ouvrir regions.html dans un navigateur.",
                    "- Choisir une région, ou ouvrir directement index.html ou un autre fichier index_*.html.",
                    "- Étape d'installation, de build ou de démarrage par commande : Not found in repo."
                ]
            )
        ]
    ),
    Summary(
        code: "en",
        languageName: "English",
        title: "My Apple Collection",
        subtitle: "App summary - English - Localized file: index_us.html",
        leftSections: [
            Section(
                title: "What it is",
                paragraphs: [
                    "A static one-page showcase for a personal Apple product collection. Each localized page keeps the same layout and sends product cards to Apple Store or Apple Support pages."
                ]
            ),
            Section(
                title: "Who it's for",
                paragraphs: [
                    "Primary persona: an Apple collector who wants to present a personal device and accessory collection to visitors."
                ]
            ),
            Section(
                title: "What it does",
                paragraphs: [
                    "- Offers a country/language selector through regions.html.",
                    "- Shows 6 anchored categories: Mac, iPad, iPhone, Watch, AirPods, and TV & Home.",
                    "- Displays product cards with images, names, and in many cases tooltip descriptions.",
                    "- Opens localized Apple Store or Apple Support links in new tabs.",
                    "- Splits products and accessories inside each category.",
                    "- Reuses one responsive grid/card layout across all localized pages.",
                    "- Adds a return link to the region selector and a copyright-triggered image popup."
                ]
            )
        ],
        rightSections: [
            Section(
                title: "How it works",
                paragraphs: [
                    "- Entry points: regions.html links to 8 localized HTML pages.",
                    "- Presentation: styles/styles.css handles product pages; styles/styles_of_regions.css handles the selector page; styles/styles_of_kiz.css styles the popup window.",
                    "- Data: product lists, copy, and Apple URLs are embedded directly inside each HTML file.",
                    "- Flow: the user chooses a region, jumps through anchored sections, and opens external Apple pages from product cards.",
                    "- Services/backend/API: Not found in repo."
                ]
            ),
            Section(
                title: "How to run",
                paragraphs: [
                    "- Open regions.html in a browser.",
                    "- Choose a region, or open index_us.html or another index_*.html file directly.",
                    "- Install, build, or CLI start step: Not found in repo."
                ]
            )
        ]
    ),
    Summary(
        code: "de",
        languageName: "German",
        title: "Meine Apple Sammlung",
        subtitle: "App-Zusammenfassung - Deutsch - Lokalisierte Datei: index_de.html",
        leftSections: [
            Section(
                title: "Was es ist",
                paragraphs: [
                    "Statische One-Page-Seite zur Präsentation einer persönlichen Apple-Sammlung. Jede lokalisierte Seite nutzt die gleiche Struktur und verlinkt Produktkarten zu Apple Store oder Apple Support."
                ]
            ),
            Section(
                title: "Für wen",
                paragraphs: [
                    "Primäre Persona: ein Apple-Sammler, der seine Geräte- und Zubehörsammlung online zeigen will."
                ]
            ),
            Section(
                title: "Funktionen",
                paragraphs: [
                    "- Bietet einen Länder-/Sprachauswahlschirm über regions.html.",
                    "- Zeigt 6 verankerte Kategorien: Mac, iPad, iPhone, Watch, AirPods und TV & Home.",
                    "- Stellt Produktkarten mit Bildern, Namen und teils Tooltip-Beschreibungen dar.",
                    "- Öffnet lokalisierte Apple Store oder Apple Support Links in neuen Tabs.",
                    "- Trennt Produkte und Zubehör innerhalb jeder Kategorie.",
                    "- Verwendet auf allen Sprachseiten dasselbe responsive Grid-/Kartenlayout.",
                    "- Enthält einen Rücklink zur Regionsauswahl und ein per Copyright ausgelöstes Bild-Popup."
                ]
            )
        ],
        rightSections: [
            Section(
                title: "So funktioniert es",
                paragraphs: [
                    "- Einstiegspunkte: regions.html verlinkt auf 8 lokalisierte HTML-Seiten.",
                    "- Darstellung: styles/styles.css für Produktseiten; styles/styles_of_regions.css für die Auswahlseite; styles/styles_of_kiz.css für das Popup.",
                    "- Daten: Produktlisten, Texte und Apple-URLs liegen direkt in den HTML-Dateien.",
                    "- Ablauf: Nutzer wählen eine Region, springen über Anker durch die Seite und öffnen externe Apple-Seiten über Produktkarten.",
                    "- Services/Backend/API: Not found in repo."
                ]
            ),
            Section(
                title: "Starten",
                paragraphs: [
                    "- regions.html im Browser öffnen.",
                    "- Eine Region wählen oder index_de.html bzw. eine andere index_*.html Datei direkt öffnen.",
                    "- Installations-, Build- oder Startbefehl: Not found in repo."
                ]
            )
        ]
    ),
    Summary(
        code: "es",
        languageName: "Spanish",
        title: "Mi Colección Apple",
        subtitle: "Resumen de la app - Español - Archivo localizado: index_es.html",
        leftSections: [
            Section(
                title: "Qué es",
                paragraphs: [
                    "Sitio estático de una sola página para mostrar una colección personal de productos Apple. Cada página localizada mantiene la misma estructura y enlaza las tarjetas a Apple Store o Apple Support."
                ]
            ),
            Section(
                title: "Para quién",
                paragraphs: [
                    "Persona principal: un coleccionista de Apple que quiere exhibir su colección de dispositivos y accesorios a visitantes."
                ]
            ),
            Section(
                title: "Qué hace",
                paragraphs: [
                    "- Ofrece un selector de país/idioma mediante regions.html.",
                    "- Muestra 6 categorías ancladas: Mac, iPad, iPhone, Watch, AirPods y TV & Home.",
                    "- Presenta tarjetas de producto con imagen, nombre y en muchos casos descripción en title.",
                    "- Abre enlaces localizados de Apple Store o Apple Support en una nueva pestaña.",
                    "- Separa productos y accesorios dentro de cada categoría.",
                    "- Reutiliza el mismo layout responsive de grilla y tarjetas en todos los idiomas.",
                    "- Agrega un enlace de regreso al selector regional y un popup de imagen activado desde el copyright."
                ]
            )
        ],
        rightSections: [
            Section(
                title: "Cómo funciona",
                paragraphs: [
                    "- Puntos de entrada: regions.html enlaza a 8 páginas HTML localizadas.",
                    "- Presentación: styles/styles.css para páginas de productos; styles/styles_of_regions.css para la selección; styles/styles_of_kiz.css para la ventana popup.",
                    "- Datos: listas de productos, textos y URLs de Apple están incrustados directamente en cada HTML.",
                    "- Flujo: el usuario elige una región, navega por anclas dentro de la página y abre páginas externas de Apple desde las tarjetas.",
                    "- Servicios/backend/API: Not found in repo."
                ]
            ),
            Section(
                title: "Cómo ejecutarlo",
                paragraphs: [
                    "- Abrir regions.html en un navegador.",
                    "- Elegir una región o abrir index_es.html u otro archivo index_*.html directamente.",
                    "- Paso de instalación, build o arranque por CLI: Not found in repo."
                ]
            )
        ]
    ),
    Summary(
        code: "it",
        languageName: "Italian",
        title: "La Mia Collezione Apple",
        subtitle: "Riepilogo dell'app - Italiano - File localizzato: index_it.html",
        leftSections: [
            Section(
                title: "Che cos'è",
                paragraphs: [
                    "Sito statico one-page che mostra una collezione personale di prodotti Apple. Ogni pagina localizzata mantiene la stessa struttura e collega le schede prodotto a Apple Store o Apple Support."
                ]
            ),
            Section(
                title: "Per chi è",
                paragraphs: [
                    "Persona principale: un collezionista Apple che vuole mostrare online la propria collezione di dispositivi e accessori."
                ]
            ),
            Section(
                title: "Cosa fa",
                paragraphs: [
                    "- Offre un selettore paese/lingua tramite regions.html.",
                    "- Mostra 6 categorie con ancore: Mac, iPad, iPhone, Watch, AirPods e TV & Home.",
                    "- Visualizza schede prodotto con immagine, nome e in molti casi descrizione nel title.",
                    "- Apre link localizzati di Apple Store o Apple Support in una nuova scheda.",
                    "- Separa prodotti e accessori dentro ogni categoria.",
                    "- Riutilizza lo stesso layout responsive a griglia e card per tutte le lingue.",
                    "- Include un link di ritorno al selettore regione e un popup immagine attivato dal copyright."
                ]
            )
        ],
        rightSections: [
            Section(
                title: "Come funziona",
                paragraphs: [
                    "- Punti di ingresso: regions.html collega 8 pagine HTML localizzate.",
                    "- Presentazione: styles/styles.css per le pagine prodotto; styles/styles_of_regions.css per il selettore; styles/styles_of_kiz.css per la finestra popup.",
                    "- Dati: elenchi prodotti, testi e URL Apple sono incorporati direttamente in ogni file HTML.",
                    "- Flusso: l'utente sceglie una regione, naviga tramite ancore nella pagina e apre pagine Apple esterne dalle card.",
                    "- Servizi/backend/API: Not found in repo."
                ]
            ),
            Section(
                title: "Come avviarlo",
                paragraphs: [
                    "- Aprire regions.html in un browser.",
                    "- Scegliere una regione oppure aprire direttamente index_it.html o un altro file index_*.html.",
                    "- Passaggio di installazione, build o avvio da CLI: Not found in repo."
                ]
            )
        ]
    ),
    Summary(
        code: "tr",
        languageName: "Turkish",
        title: "Apple Koleksiyonum",
        subtitle: "Uygulama özeti - Türkçe - Yerel dosya: index_tr.html",
        leftSections: [
            Section(
                title: "Nedir",
                paragraphs: [
                    "Kişisel Apple ürün koleksiyonunu gösteren statik bir tek sayfa sitesidir. Her yerelleştirilmiş sayfa aynı yapıyı korur ve ürün kartlarını Apple Store veya Apple Support sayfalarına bağlar."
                ]
            ),
            Section(
                title: "Kimin için",
                paragraphs: [
                    "Birincil persona: cihaz ve aksesuar koleksiyonunu ziyaretçilere göstermek isteyen bir Apple koleksiyoncusu."
                ]
            ),
            Section(
                title: "Ne yapar",
                paragraphs: [
                    "- regions.html üzerinden ülke/dil seçimi sunar.",
                    "- 6 sabit bölüm gösterir: Mac, iPad, iPhone, Watch, AirPods ve TV & Home.",
                    "- Görsel, ad ve çoğu yerde title açıklaması içeren ürün kartları sunar.",
                    "- Yerelleştirilmiş Apple Store veya Apple Support bağlantılarını yeni sekmede açar.",
                    "- Her kategori içinde ürünleri ve aksesuarları ayırır.",
                    "- Tüm dillerde aynı responsive grid ve kart düzenini kullanır.",
                    "- Bölge seçicisine dönüş linki ve copyright üzerinden açılan bir görsel popup ekler."
                ]
            )
        ],
        rightSections: [
            Section(
                title: "Nasıl çalışır",
                paragraphs: [
                    "- Giriş noktaları: regions.html 8 yerelleştirilmiş HTML sayfasına bağlanır.",
                    "- Sunum: styles/styles.css ürün sayfalarını; styles/styles_of_regions.css seçici sayfasını; styles/styles_of_kiz.css popup penceresini stiller.",
                    "- Veri: ürün listeleri, metinler ve Apple URL'leri doğrudan HTML dosyalarına gömülüdür.",
                    "- Akış: kullanıcı bölge seçer, sayfa içindeki anchor'larla gezer ve ürün kartlarından harici Apple sayfalarını açar.",
                    "- Servis/backend/API: Not found in repo."
                ]
            ),
            Section(
                title: "Nasıl çalıştırılır",
                paragraphs: [
                    "- regions.html dosyasını tarayıcıda açın.",
                    "- Bir bölge seçin veya doğrudan index_tr.html ya da başka bir index_*.html dosyasını açın.",
                    "- Kurulum, build veya CLI başlatma adımı: Not found in repo."
                ]
            )
        ]
    ),
    Summary(
        code: "ja",
        languageName: "Japanese",
        title: "私のAppleコレクション",
        subtitle: "アプリ概要 - 日本語 - ローカライズ済みファイル: index_jp.html",
        leftSections: [
            Section(
                title: "これは何か",
                paragraphs: [
                    "個人のApple製品コレクションを見せる静的な1ページサイトです。各言語ページは同じ構成を使い、商品カードからApple StoreまたはApple Supportへ移動します。"
                ]
            ),
            Section(
                title: "対象ユーザー",
                paragraphs: [
                    "主なペルソナ: 自分のAppleデバイスとアクセサリのコレクションを訪問者に見せたいコレクター。"
                ]
            ),
            Section(
                title: "できること",
                paragraphs: [
                    "- regions.html で国と言語の選択画面を提供します。",
                    "- Mac、iPad、iPhone、Watch、AirPods、TV & Home の6カテゴリをアンカー付きで表示します。",
                    "- 画像、名称、そして多くの項目で title による説明付きの商品カードを表示します。",
                    "- ローカライズされた Apple Store または Apple Support のリンクを新しいタブで開きます。",
                    "- 各カテゴリ内で本体製品とアクセサリを分けて表示します。",
                    "- すべての言語ページで同じレスポンシブなグリッド/カードレイアウトを再利用します。",
                    "- 地域選択へ戻るリンクと、copyright から起動する画像ポップアップがあります。"
                ]
            )
        ],
        rightSections: [
            Section(
                title: "仕組み",
                paragraphs: [
                    "- 入口: regions.html から8つのローカライズ済みHTMLページへ移動します。",
                    "- 表示: styles/styles.css が製品ページ、styles/styles_of_regions.css が選択ページ、styles/styles_of_kiz.css がポップアップを担当します。",
                    "- データ: 商品一覧、文言、Apple URL は各HTMLファイルに直接埋め込まれています。",
                    "- 流れ: ユーザーが地域を選び、アンカーでページ内を移動し、商品カードから外部のAppleページを開きます。",
                    "- Services/backend/API: Not found in repo."
                ]
            ),
            Section(
                title: "実行方法",
                paragraphs: [
                    "- ブラウザで regions.html を開きます。",
                    "- 地域を選ぶか、index_jp.html または別の index_*.html を直接開きます。",
                    "- インストール、ビルド、CLI起動手順: Not found in repo."
                ]
            )
        ]
    ),
    Summary(
        code: "zh",
        languageName: "Chinese",
        title: "我的苹果收藏",
        subtitle: "应用摘要 - 中文 - 本地化文件: index_cn.html",
        leftSections: [
            Section(
                title: "它是什么",
                paragraphs: [
                    "这是一个展示个人 Apple 产品收藏的静态单页网站。每个本地化页面都沿用相同结构，并把产品卡片链接到 Apple Store 或 Apple Support。"
                ]
            ),
            Section(
                title: "面向谁",
                paragraphs: [
                    "主要用户画像: 想向访客展示自己 Apple 设备和配件收藏的收藏者。"
                ]
            ),
            Section(
                title: "它做什么",
                paragraphs: [
                    "- 通过 regions.html 提供国家/语言选择页。",
                    "- 展示 6 个带锚点的分类：Mac、iPad、iPhone、Watch、AirPods、TV & Home。",
                    "- 用产品卡片展示图片、名称，以及很多条目的 title 说明。",
                    "- 在新标签页打开本地化的 Apple Store 或 Apple Support 链接。",
                    "- 在每个分类中区分设备和配件。",
                    "- 在所有语言页面中复用同一套响应式网格和卡片布局。",
                    "- 提供返回地区选择页的链接，以及由 copyright 触发的图片弹窗。"
                ]
            )
        ],
        rightSections: [
            Section(
                title: "如何运作",
                paragraphs: [
                    "- 入口：regions.html 链接到 8 个本地化 HTML 页面。",
                    "- 表现层：styles/styles.css 用于产品页；styles/styles_of_regions.css 用于地区选择页；styles/styles_of_kiz.css 用于弹窗页。",
                    "- 数据：产品列表、文案和 Apple URL 都直接写在各个 HTML 文件里。",
                    "- 流程：用户先选地区，再通过锚点浏览页面，并从产品卡片打开外部 Apple 页面。",
                    "- Services/backend/API: Not found in repo."
                ]
            ),
            Section(
                title: "如何运行",
                paragraphs: [
                    "- 在浏览器中打开 regions.html。",
                    "- 选择一个地区，或直接打开 index_cn.html 或其他 index_*.html 文件。",
                    "- 安装、构建或 CLI 启动步骤: Not found in repo."
                ]
            )
        ]
    )
]

func render(summary: Summary) throws -> URL {
    let pageRect = CGRect(x: 0, y: 0, width: 595.0, height: 842.0)
    let margin: CGFloat = 34
    let gutter: CGFloat = 20
    let footerHeight: CGFloat = 28
    let titleBlockHeight: CGFloat = 56
    let columnWidth = (pageRect.width - (margin * 2) - gutter) / 2
    let columnsTop = margin + titleBlockHeight
    let availableHeight = pageRect.height - columnsTop - margin - footerHeight
    let theme = makeTheme(bodySize: fittingBodySize(for: summary, columnWidth: columnWidth, availableHeight: availableHeight))

    let url = outputDir.appendingPathComponent("apple_collection_summary_\(summary.code).pdf")
    let data = NSMutableData()
    var mediaBox = pageRect

    guard let consumer = CGDataConsumer(data: data as CFMutableData),
          let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
        throw NSError(domain: "PDF", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create PDF context"])
    }

    context.beginPDFPage(nil)
    let graphics = NSGraphicsContext(cgContext: context, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphics

    NSColor.white.setFill()
    NSBezierPath(rect: pageRect).fill()

    let titleWidth = pageRect.width - (margin * 2)
    let titleAttr = attributed(summary.title, font: theme.titleFont, color: theme.titleColor, lineSpacing: 0.5, paragraphSpacing: 0)
    _ = renderText(titleAttr, x: margin, y: margin, width: titleWidth, pageHeight: pageRect.height)

    let subtitleAttr = attributed(summary.subtitle, font: theme.subtitleFont, color: theme.subtitleColor, lineSpacing: 0.8, paragraphSpacing: 0)
    _ = renderText(subtitleAttr, x: margin, y: margin + 27, width: titleWidth, pageHeight: pageRect.height)

    theme.lineColor.setFill()
    NSBezierPath(rect: NSRect(x: margin, y: pageRect.height - (margin + 46) - 1, width: titleWidth, height: 1)).fill()

    let leftX = margin
    let rightX = margin + columnWidth + gutter
    var leftY = columnsTop
    var rightY = columnsTop

    for section in summary.leftSections {
        leftY = renderSection(section, x: leftX, y: leftY, width: columnWidth, pageHeight: pageRect.height, theme: theme)
    }

    for section in summary.rightSections {
        rightY = renderSection(section, x: rightX, y: rightY, width: columnWidth, pageHeight: pageRect.height, theme: theme)
    }

    let noteAttr = attributed(evidenceNote, font: theme.noteFont, color: theme.subtitleColor, lineSpacing: 0.8, paragraphSpacing: 0)
    _ = renderText(noteAttr, x: margin, y: pageRect.height - margin - footerHeight + 6, width: titleWidth, pageHeight: pageRect.height)

    NSGraphicsContext.restoreGraphicsState()
    context.endPDFPage()
    context.closePDF()
    try data.write(to: url)
    return url
}

for summary in summaries {
    let url = try render(summary: summary)
    print(url.path)
}
