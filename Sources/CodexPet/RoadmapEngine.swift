import Foundation

struct RoadmapMonth: Sendable {
    let focus: String
    let repository: String
    let weekdayTasks: [String]
}

struct RoadmapEngine: Sendable {
    static let startDate: Date = {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(identifier: "Europe/Istanbul")
        components.year = 2026
        components.month = 8
        components.day = 25
        return components.date!
    }()

    private let calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    func plan(for date: Date) -> RoadmapDay {
        let day = dayNumber(for: date)
        let month = monthNumber(forDay: day)
        let roadmapMonth = Self.months[month - 1]
        let weekdayIndex = mondayBasedWeekdayIndex(for: date)
        let primary = roadmapMonth.weekdayTasks[weekdayIndex]
        let support = supportTask(for: weekdayIndex, repository: roadmapMonth.repository)

        return RoadmapDay(
            dayNumber: day,
            monthNumber: month,
            milestone: "Q\(((month - 1) / 3) + 1)",
            focus: roadmapMonth.focus,
            repository: roadmapMonth.repository,
            tasks: [
                DailyTask(
                    title: primary,
                    detail: roadmapMonth.repository,
                    category: primaryCategory(for: weekdayIndex),
                    estimatedMinutes: weekdayIndex == 5 ? 120 : 40
                ),
                DailyTask(
                    title: support,
                    detail: "Çalışmayı ölçülebilir ve tekrar üretilebilir tut.",
                    category: weekdayIndex == 3 ? .aws : .test,
                    estimatedMinutes: 25
                ),
                DailyTask(
                    title: "Anlamlı GitHub katkısını tamamla",
                    detail: "Kod, test, doküman, issue, PR veya review - boş commit yok.",
                    category: .github,
                    estimatedMinutes: 15
                )
            ]
        )
    }

    func dayNumber(for date: Date) -> Int {
        let start = calendar.startOfDay(for: Self.startDate)
        let current = calendar.startOfDay(for: date)
        let difference = calendar.dateComponents([.day], from: start, to: current).day ?? 0
        return min(365, max(1, difference + 1))
    }

    func monthNumber(forDay day: Int) -> Int {
        let boundaries = [30, 61, 91, 122, 152, 183, 213, 244, 274, 305, 335, 365]
        return (boundaries.firstIndex(where: { day <= $0 }) ?? 11) + 1
    }

    private func mondayBasedWeekdayIndex(for date: Date) -> Int {
        let appleWeekday = calendar.component(.weekday, from: date)
        return (appleWeekday + 5) % 7
    }

    private func primaryCategory(for weekday: Int) -> TaskCategory {
        switch weekday {
        case 0: .learn
        case 1, 5: .build
        case 2: .test
        case 3: .aws
        case 4: .review
        default: .review
        }
    }

    private func supportTask(for weekday: Int, repository: String) -> String {
        switch weekday {
        case 0: "Öğrendiğin konu için üç maddelik teknik not yaz"
        case 1: "Yeni davranış için en az bir test ekle"
        case 2: "Başarısız örnekleri sınıflandır ve sonucu kaydet"
        case 3: "AWS maliyet, IAM ve hata senaryosunu kontrol et"
        case 4: "README veya mimari karar kaydını güncelle"
        case 5: "Feature'ı demo edilebilir küçük bir dilime tamamla"
        default: "Haftayı değerlendir ve gelecek yedi issue'yu hazırla"
        }
    }

    static let months: [RoadmapMonth] = [
        RoadmapMonth(
            focus: "ML ve Veri Temelleri",
            repository: "production-ml-classifier",
            weekdayTasks: [
                "NumPy ve Pandas veri akışını çalış",
                "Veri temizleme fonksiyonu geliştir",
                "Baseline model ve F1 metriği ekle",
                "IAM ve S3 hands-on laboratuvarı yap",
                "Data leakage kontrol listesi yaz",
                "Feature pipeline'ı uçtan uca çalıştır",
                "Haftalık ML deney sonuçlarını özetle"
            ]
        ),
        RoadmapMonth(
            focus: "Production ML",
            repository: "production-ml-classifier",
            weekdayTasks: [
                "Cross-validation ve hata analizini çalış",
                "FastAPI inference endpoint'i geliştir",
                "Model ve API testlerini genişlet",
                "Model artifact'ını S3'e yükle",
                "Model card ve limitations bölümünü yaz",
                "Docker ve CI hattını tamamla",
                "v1.0 kapsamını ve issue'ları düzenle"
            ]
        ),
        RoadmapMonth(
            focus: "Transformer İç Yapısı",
            repository: "tiny-transformer-from-scratch",
            weekdayTasks: [
                "Tokenization ve embedding kavramlarını çalış",
                "Self-attention katmanını geliştir",
                "Attention mask testlerini ekle",
                "Küçük eğitim işini AWS üzerinde dene",
                "Transformer mimari dokümanını güncelle",
                "Training loop ve visualization tamamla",
                "Q1 release ve retrospective hazırla"
            ]
        ),
        RoadmapMonth(
            focus: "Production AI API Engineering",
            repository: "multi-provider-ai-gateway",
            weekdayTasks: [
                "Provider adapter sözleşmesini tasarla",
                "Streaming ve structured output geliştir",
                "Retry, timeout ve contract testleri ekle",
                "Bedrock provider adapter'ını geliştir",
                "API güvenlik ve secret notlarını yaz",
                "Fallback ve cost tracking tamamla",
                "Gateway release kapsamını düzenle"
            ]
        ),
        RoadmapMonth(
            focus: "Multilingual RAG",
            repository: "multilingual-rag-benchmark",
            weekdayTasks: [
                "Embedding ve retrieval yöntemlerini çalış",
                "TR/DE/EN ingestion pipeline geliştir",
                "Retrieval recall testlerini ekle",
                "RAG demo altyapısını AWS'e taşı",
                "Failure taxonomy ve README güncelle",
                "Hybrid retrieval benchmark çalıştır",
                "Haftalık benchmark sonuçlarını yayınla"
            ]
        ),
        RoadmapMonth(
            focus: "LLM Evaluation",
            repository: "llm-quality-gate",
            weekdayTasks: [
                "Golden dataset ve grader tasarımını çalış",
                "Model karşılaştırma runner'ı geliştir",
                "Quality regression testlerini ekle",
                "CI rapor artifact'ını AWS'e yükle",
                "Eval metodolojisini dokümante et",
                "GitHub Actions quality gate tamamla",
                "Q2 release ve retrospective hazırla"
            ]
        ),
        RoadmapMonth(
            focus: "Güvenli AI Agent'ları",
            repository: "secure-agent-runtime",
            weekdayTasks: [
                "Agent loop ve tool permission modelini çalış",
                "Tool allowlist ve schema validation geliştir",
                "Prompt injection test seti ekle",
                "Audit loglarını CloudWatch'a gönder",
                "Threat model ve güvenlik notlarını yaz",
                "Human approval akışını tamamla",
                "Attack success rate sonuçlarını özetle"
            ]
        ),
        RoadmapMonth(
            focus: "AWS MLOps",
            repository: "aws-mlops-blueprint",
            weekdayTasks: [
                "MLA-C01 data preparation domainini çalış",
                "SageMaker training pipeline geliştir",
                "Model evaluation testlerini ekle",
                "S3, Glue ve pipeline entegrasyonu yap",
                "IAM ve encryption kararlarını yaz",
                "Model Registry ve endpoint deploy et",
                "AWS maliyetlerini ve issue'ları değerlendir"
            ]
        ),
        RoadmapMonth(
            focus: "AWS MLA-C01 ve Operasyon",
            repository: "aws-mlops-blueprint",
            weekdayTasks: [
                "MLA-C01 zayıf domainini tekrar et",
                "Monitoring veya drift özelliği geliştir",
                "AWS hata senaryosu testi ekle",
                "Deneme sınavı ve yanlış analizi yap",
                "Mimari ve operasyon runbook'unu güncelle",
                "IaC ve CI/CD hattını tamamla",
                "Q3 release ve sertifika durumunu değerlendir"
            ]
        ),
        RoadmapMonth(
            focus: "Small LLM Fine-tuning",
            repository: "small-llm-finetuning-lab",
            weekdayTasks: [
                "PEFT ve LoRA yaklaşımını çalış",
                "Dataset pipeline ve baseline geliştir",
                "Before/after eval testlerini ekle",
                "Training job maliyetini AWS'de ölç",
                "Dataset ve model card güncelle",
                "Fine-tuning deneyini tamamla",
                "Deney sonuçlarını ve hataları özetle"
            ]
        ),
        RoadmapMonth(
            focus: "Multilingual AI Capstone",
            repository: "multilingual-learning-copilot",
            weekdayTasks: [
                "Capstone use-case ve metriklerini netleştir",
                "RAG veya agent feature'ı geliştir",
                "Capstone eval ve security testi ekle",
                "AWS deployment parçasını tamamla",
                "ADR ve architecture diagram güncelle",
                "Uçtan uca kullanıcı akışını tamamla",
                "Demo risklerini ve gelecek issue'ları değerlendir"
            ]
        ),
        RoadmapMonth(
            focus: "Capstone Launch ve Profil",
            repository: "multilingual-learning-copilot",
            weekdayTasks: [
                "Kalan kalite kapısını tamamla",
                "Demo deneyimini ve performansı iyileştir",
                "Regression ve güvenlik testlerini çalıştır",
                "AWS monitoring ve maliyeti son kez kontrol et",
                "README, CV ve pinned repo metinlerini güncelle",
                "v1.0 release ve teknik yazıyı yayınla",
                "365 günlük retrospective ve sonraki planı yaz"
            ]
        )
    ]
}
