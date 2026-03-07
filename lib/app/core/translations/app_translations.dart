import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'onboarding_skip': 'Skip',
      'onboarding_previous': 'Previous',
      'onboarding_next': 'Next',
      'onboarding_done': 'Get Started',
      'onboarding_welcome_title': 'Welcome to FitScript AI',
      'onboarding_welcome_body':
          'Scan your lab results and get fast analysis with easy-to-understand explanations.',
      'onboarding_features_title': 'Featured capabilities',
      'onboarding_privacy_title': 'Privacy is a priority',
      'onboarding_privacy_body':
          'Your medical data is secure and encrypted. FitScript AI is an educational and informational tool, not a substitute for professional medical advice, diagnosis, or treatment.',
      'onboarding_feature_1': 'Instant scan & analysis for lab results.',
      'onboarding_feature_2':
          'Plain-language explanations without complex terms.',
      'onboarding_feature_3': 'Track health trends from your test history.',
      'onboarding_feature_4':
          'Personal lifestyle guidance based on lab results.',
      'legal_privacy_title': 'Privacy Policy',
      'legal_terms_title': 'Terms and Conditions',
      'legal_agree_button': 'I Agree',
      'legal_last_updated': 'Last Updated: @date',
      'legal_toc_title': 'Table of Contents',
      'legal_load_error': 'Document cannot be loaded at this time.',
      'legal_back_to_top_tooltip': 'Back to top',
      'consent_saved_title': 'Consent saved',
      'consent_saved_privacy': 'Privacy Policy has been accepted.',
      'consent_saved_terms': 'Terms and Conditions have been accepted.',
      'consent_failed_title': 'Failed to save consent',
      'consent_failed_no_session':
          'Account session is not available. Please try again.',
      'consent_failed_server':
          'There was a problem saving consent to the server.',
      'tab_home': 'FitScript AI',
      'tab_history': 'Test History',
      'tab_profile': 'Profile',
      'nav_home': 'Home',
      'nav_history': 'History',
      'nav_account': 'Account',
      'history_title': 'Lab Result History',
      'history_subtitle': 'Track your test result changes over time.',
      'history_metric_total': 'Total Tests',
      'history_metric_warning': 'Needs Attention',
      'history_metric_improve': 'Improving',
      'history_snackbar_title': 'Test history',
      'history_snackbar_message': 'Opening detail: @title',
      'history_status_warning': 'Warning',
      'history_status_improve': 'Improving',
      'history_status_normal': 'Stable',
      'history_loading': 'Loading analysis history...',
      'history_empty_title': 'No analysis history yet',
      'history_empty_subtitle':
          'Your uploaded lab analysis results will appear here.',
      'history_delete_confirm_title': 'Delete history?',
      'history_delete_confirm_message':
          'The analysis "@title" will be removed from your history.',
      'history_delete_success_title': 'History deleted',
      'history_delete_success_message':
          'The analysis has been removed from your history.',
      'history_delete_failed_title': 'Delete failed',
      'history_delete_failed_message':
          'Unable to delete history right now. Please try again.',
      'history_unknown_title': 'Lab Analysis',
      'history_unknown_note': 'No summary available.',
      'history_sample_1_title': 'Complete blood count',
      'history_sample_1_note': 'Needs attention: Hemoglobin',
      'history_sample_2_title': 'Lipid profile',
      'history_sample_2_note': 'Improving: Total cholesterol decreased',
      'history_sample_3_title': 'Fasting blood glucose',
      'history_sample_3_note': 'Stable: Within reference range',
      'home_title': 'Your personal health assistant',
      'home_subtitle':
          'Scan lab results and understand your condition with fast analysis, plain language, and relevant advice.',
      'home_start_analysis_title': 'Start a new analysis',
      'home_start_analysis_subtitle':
          'Take a photo, upload an image, or select a PDF lab result and get instant explanations in easy language.',
      'home_upload_button': 'Capture Lab Result',
      'home_take_photo_button': 'Camera',
      'home_pick_gallery_button': 'Gallery',
      'home_pick_pdf_button': 'Upload PDF Document',
      'home_selected_image': 'Selected lab image',
      'home_selected_document': 'Selected lab document',
      'home_analyze_button': 'Analyze with AI',
      'home_analyzing_button': 'Analyzing...',
      'home_analyze_trial_exhausted_button': 'Free Trial Ended',
      'home_analysis_result_title': 'AI Analysis Result',
      'home_analysis_findings_label': 'Key findings',
      'home_analysis_recommendation_label': 'Recommendation',
      'home_analysis_next_steps_label': 'Next steps',
      'home_save_analysis_button': 'Save Analysis Result',
      'home_saving_analysis_button': 'Saving...',
      'home_saved_analysis_button': 'Already Saved',
      'home_save_trial_exhausted_button': 'Free Trial Ended',
      'home_saved_title': 'Analysis saved',
      'home_saved_message': 'Analysis result has been added to your history.',
      'home_saved_dialog_title': 'Saved successfully',
      'home_saved_dialog_message':
          'Your analysis has been stored and is ready to review in History.',
      'home_saved_dialog_open_history': 'Open History',
      'home_trial_analysis_limit_title': 'Free trial limit reached',
      'home_trial_analysis_limit_message':
          'You have used all @max free analysis attempts.',
      'home_trial_save_limit_title': 'Free trial limit reached',
      'home_trial_save_limit_message':
          'You have used all @max free save attempts.',
      'home_pick_failed_title': 'Image selection failed',
      'home_pick_failed_message':
          'Unable to read the selected image. Please try again.',
      'home_file_too_large_title': 'File is too large',
      'home_file_too_large_message':
          'Maximum document size is 500 KB. Please upload a smaller file.',
      'home_pdf_only_title': 'Invalid file type',
      'home_pdf_only_message': 'Please choose a PDF document (.pdf).',
      'home_picker_unavailable_title': 'File picker unavailable',
      'home_picker_unavailable_message':
          'File picker plugin is not ready. Please fully restart the app and try again.',
      'home_file_size_label': 'File size: @size',
      'home_file_compressed_note': 'Compressed from @before to @after.',
      'home_preparing_document': 'Optimizing document to fit 500 KB limit...',
      'home_preparing_document_short': 'Optimizing...',
      'home_preparing_wait_title': 'Please wait',
      'home_preparing_wait_message':
          'Document optimization is still in progress.',
      'home_no_image_title': 'No image selected',
      'home_no_image_message':
          'Please capture or upload a lab result image first.',
      'home_no_document_title': 'No document selected',
      'home_no_document_message':
          'Please capture, upload, or select a lab result document first.',
      'home_analyze_failed_title': 'Analysis failed',
      'home_analyze_failed_message':
          'Unable to analyze the image right now. Please try again.',
      'home_save_failed_title': 'Save failed',
      'home_save_failed_message':
          'Unable to save the analysis result. Please try again.',
      'home_save_failed_no_user':
          'User session is not available. Please try again.',
      'home_summary_warning':
          'Some indicators may need attention based on this lab image.',
      'home_summary_improve':
          'Your indicators show signs of improvement compared to common patterns.',
      'home_summary_normal':
          'Most visible indicators appear within expected range patterns.',
      'home_recommendation_warning':
          'Consult a healthcare professional for confirmation and next steps.',
      'home_recommendation_improve':
          'Maintain your current healthy habits and continue monitoring trends.',
      'home_recommendation_normal':
          'Keep a balanced diet and regular activity, then re-check routinely.',
      'home_status_warning': 'Warning',
      'home_status_improve': 'Improving',
      'home_status_normal': 'Stable',
      'home_featured_title': 'Featured capabilities',
      'home_feature_1_title': 'Instant scan & analysis',
      'home_feature_1_subtitle':
          'Capture blood, urine, cholesterol lab results and get an automatic summary in seconds.',
      'home_feature_2_title': 'Simple explanations',
      'home_feature_2_subtitle':
          'Understand what your lab numbers mean in plain language.',
      'home_feature_3_title': 'Track health trends',
      'home_feature_3_subtitle':
          'Save test history and monitor your health indicators over time.',
      'home_feature_4_title': 'Personal lifestyle guidance',
      'home_feature_4_subtitle':
          'Get activity and nutrition recommendations based on your lab results.',
      'home_feature_5_title': 'Privacy protected',
      'home_feature_5_subtitle':
          'Your medical data is secured and encrypted to protect personal privacy.',
      'home_sample_insight_button': 'View Sample Analysis',
      'home_disclaimer':
          'FitScript AI is not a substitute for professional medical advice, diagnosis, or treatment. Always consult your doctor or qualified healthcare professional before making medical decisions.',
      'home_upload_snackbar_title': 'Upload feature',
      'home_upload_snackbar_message':
          'Ready for camera/gallery integration for lab documents.',
      'home_sample_insight_title': 'Sample analysis',
      'home_sample_insight_message':
          'Hemoglobin is slightly below normal. Consider iron-rich foods and always confirm with your doctor.',
      'profile_title_account_subscription': 'Account & Subscription',
      'profile_subscription_status': 'Subscription Status',
      'profile_subscription_free_plan': 'Free Plan',
      'profile_subscription_premium_plan': 'Premium (FitScript Pro)',
      'profile_subscription_description':
          'Upgrade to unlock all features and remove trial limits.',
      'profile_subscription_premium_description':
          'Premium is active. You have full access to analysis and save features.',
      'profile_trial_usage': 'Trial Usage',
      'profile_trial_unlimited_message':
          'Unlimited access is active for analysis and save actions.',
      'profile_trial_left': '@count left',
      'profile_trial_lab_result_analysis': 'Lab Result Analysis',
      'profile_trial_save_analysis_result': 'Save Analysis Result',
      'profile_privacy_policy': 'Privacy Policy',
      'profile_terms_conditions': 'Terms and Conditions',
      'profile_danger_zone': 'Danger Zone',
      'profile_danger_zone_description':
          'Delete your account and all related data in Firestore. This action cannot be undone. If Firebase asks for recent login, re-authenticate using the buttons above.',
      'profile_upgrade_button': 'Upgrade to Premium',
      'profile_restore_button': 'Restore Purchases',
      'profile_sign_out_button': 'Sign Out',
      'profile_sign_out_confirm_title': 'Sign out now?',
      'profile_sign_out_confirm_message':
          'You will continue as a guest account on this device.',
      'profile_sign_out_failed_title': 'Sign out failed',
      'profile_sign_out_failed_message':
          'There was a problem signing out. Please try again.',
      'profile_upgrade_info_title': 'Upgrade to Premium',
      'profile_upgrade_info_message':
          'Premium upgrade flow will be available in a future release.',
      'premium_title': 'Upgrade to Premium',
      'premium_plan_name': 'Premium (FitScript Pro)',
      'premium_subtitle':
          'Unlock full capabilities for families and long-term health monitoring.',
      'premium_feature_scan_title': 'Unlimited Scanning',
      'premium_feature_scan_subtitle':
          'Ideal for families or seniors with many lab reports.',
      'premium_feature_insight_title': 'Deep Insight',
      'premium_feature_insight_subtitle':
          'AI explains results and gives detailed nutrition and workout guidance.',
      'premium_feature_trend_title': 'Trend Analysis',
      'premium_feature_trend_subtitle':
          'Compare lab results over time, such as cholesterol progress across 1 year.',
      'premium_feature_export_title': 'Export to PDF',
      'premium_feature_export_subtitle':
          'Generate a neat summary report to bring to your doctor.',
      'premium_pricing_title': 'Pricing (Dynamic by region)',
      'premium_pricing_market_id': 'Indonesia',
      'premium_pricing_market_global': 'Global',
      'premium_price_id_monthly': 'Rp 29.000 / month',
      'premium_price_id_yearly': 'Rp 199.000 / year',
      'premium_price_global_monthly': '\$4.99 / month',
      'premium_price_global_yearly': '\$39.99 / year',
      'premium_pricing_note':
          'Displayed package can adapt to your locale and app store region.',
      'premium_cta_upgrade': 'Upgrade Now',
      'profile_restore_info_title': 'Restore Purchases',
      'profile_restore_info_message':
          'Purchase restoration is not available in this version yet.',
      'profile_user_default': 'FitScript AI User',
      'profile_user_not_connected': 'Account not connected yet',
      'profile_language': 'Language',
      'profile_language_changed': 'Language updated',
      'profile_language_changed_message': 'App language changed to @language.',
      'profile_language_english': 'English',
      'profile_language_indonesian': 'Indonesian',
      'profile_cancel': 'Cancel',
      'profile_close': 'Close',
      'profile_account_sync_title': 'Account Sync',
      'profile_account_sync_anonymous':
          'Connect your account to keep recipes, chats, and subscription data synced across devices.',
      'profile_account_sync_connected':
          'Connected as @name. Your data is synced across devices.',
      'profile_connect_google': 'Connect with Google',
      'profile_connect_apple': 'Connect with Apple',
      'profile_connecting': 'Connecting...',
      'profile_delete_title': 'Delete account?',
      'profile_delete_message':
          'All account data will be permanently deleted and cannot be restored.',
      'profile_delete_button': 'Delete',
      'profile_deleting': 'Deleting...',
      'profile_delete_success_title': 'Account deleted',
      'profile_delete_success_message':
          'Account deleted successfully. You are signed in again as a guest.',
      'profile_delete_recent_login_title': 'Recent login required',
      'profile_delete_recent_login_message':
          'Please re-authenticate with Google/Apple then try deleting again.',
      'profile_delete_cancelled_title': 'Cancelled',
      'profile_delete_cancelled_message':
          'Re-authentication process was cancelled.',
      'profile_delete_failed_title': 'Delete failed',
      'profile_delete_failed_message':
          'Something went wrong while deleting the account.',
      'profile_delete_failed_message_with_code':
          'Something went wrong while deleting the account (@code).',
      'profile_delete_error_message':
          'An error occurred while deleting the account. Please try again.',
      'profile_link_success_title': 'Account connected',
      'profile_link_success_message':
          '@provider account connected successfully.',
      'profile_login_success_title': 'Sign-in successful',
      'profile_login_success_message':
          '@provider account was already linked and is now signed in.',
      'profile_link_google_failed_title': 'Google link failed',
      'profile_link_google_failed_message':
          'There was a problem connecting your Google account.',
      'profile_link_apple_failed_title': 'Apple link failed',
      'profile_link_apple_failed_message':
          'There was a problem connecting your Apple account.',
      'profile_auth_error_different_credential':
          'Account already exists with a different sign-in method. Please use the correct method.',
      'profile_auth_error_invalid_credential':
          'Invalid credential. Please try signing in again.',
      'profile_auth_error_apple_invalid':
          'Apple sign-in returned an invalid response. Make sure your Apple ID is signed in on this device and try again.',
      'profile_auth_error_apple_setup':
          'Apple sign-in token is missing. Verify Sign in with Apple is enabled in Apple Developer and Firebase Console.',
      'profile_auth_error_generic':
          'Authentication error occurred. Please try again.',
    },
    'id_ID': {
      'onboarding_skip': 'Lewati',
      'onboarding_previous': 'Sebelumnya',
      'onboarding_next': 'Lanjut',
      'onboarding_done': 'Mulai',
      'onboarding_welcome_title': 'Selamat Datang di FitScript AI',
      'onboarding_welcome_body':
          'Scan hasil lab Anda dan dapatkan analisis cepat dengan penjelasan yang mudah dipahami.',
      'onboarding_features_title': 'Fitur Unggulan',
      'onboarding_privacy_title': 'Privasi Tetap Prioritas',
      'onboarding_privacy_body':
          'Data medis Anda aman dan terenkripsi. FitScript AI adalah alat edukasi dan informasi, bukan pengganti saran, diagnosis, atau perawatan medis profesional.',
      'onboarding_feature_1': 'Scan & analisis instan hasil lab.',
      'onboarding_feature_2': 'Penjelasan bahasa awam tanpa istilah rumit.',
      'onboarding_feature_3': 'Pantau tren kesehatan dari riwayat tes.',
      'onboarding_feature_4': 'Saran gaya hidup personal sesuai hasil lab.',
      'legal_privacy_title': 'Kebijakan Privasi',
      'legal_terms_title': 'Syarat dan Ketentuan',
      'legal_agree_button': 'Saya Setuju',
      'legal_last_updated': 'Terakhir diperbarui: @date',
      'legal_toc_title': 'Daftar Isi',
      'legal_load_error': 'Dokumen tidak dapat dimuat saat ini.',
      'legal_back_to_top_tooltip': 'Kembali ke atas',
      'consent_saved_title': 'Persetujuan tersimpan',
      'consent_saved_privacy': 'Privacy Policy berhasil disetujui.',
      'consent_saved_terms': 'Terms and Conditions berhasil disetujui.',
      'consent_failed_title': 'Gagal menyimpan persetujuan',
      'consent_failed_no_session': 'Sesi akun tidak tersedia. Coba lagi.',
      'consent_failed_server': 'Terjadi kendala saat menyimpan ke server.',
      'tab_home': 'FitScript AI',
      'tab_history': 'Riwayat Tes',
      'tab_profile': 'Profil',
      'nav_home': 'Beranda',
      'nav_history': 'Riwayat',
      'nav_account': 'Akun',
      'history_title': 'Riwayat Hasil Lab',
      'history_subtitle':
          'Pantau perubahan hasil tes Anda dari waktu ke waktu.',
      'history_metric_total': 'Total Tes',
      'history_metric_warning': 'Perhatian',
      'history_metric_improve': 'Membaik',
      'history_snackbar_title': 'Riwayat tes',
      'history_snackbar_message': 'Membuka detail: @title',
      'history_status_warning': 'Perhatian',
      'history_status_improve': 'Membaik',
      'history_status_normal': 'Stabil',
      'history_loading': 'Memuat riwayat analisis...',
      'history_empty_title': 'Belum ada riwayat analisis',
      'history_empty_subtitle':
          'Hasil analisis dari upload lab Anda akan muncul di sini.',
      'history_delete_confirm_title': 'Hapus riwayat?',
      'history_delete_confirm_message':
          'Analisis "@title" akan dihapus dari riwayat Anda.',
      'history_delete_success_title': 'Riwayat dihapus',
      'history_delete_success_message':
          'Analisis berhasil dihapus dari riwayat Anda.',
      'history_delete_failed_title': 'Gagal menghapus',
      'history_delete_failed_message':
          'Tidak dapat menghapus riwayat saat ini. Silakan coba lagi.',
      'history_unknown_title': 'Analisis Hasil Lab',
      'history_unknown_note': 'Ringkasan belum tersedia.',
      'history_sample_1_title': 'Pemeriksaan darah lengkap',
      'history_sample_1_note': 'Perlu perhatian: Hemoglobin',
      'history_sample_2_title': 'Profil lipid',
      'history_sample_2_note': 'Membaik: Kolesterol total menurun',
      'history_sample_3_title': 'Gula darah puasa',
      'history_sample_3_note': 'Stabil: Dalam rentang referensi',
      'home_title': 'Asisten kesehatan pribadi Anda',
      'home_subtitle':
          'Scan hasil lab dan pahami kondisi Anda lewat analisis cepat, bahasa awam, dan saran yang relevan.',
      'home_start_analysis_title': 'Mulai analisis baru',
      'home_start_analysis_subtitle':
          'Ambil foto, upload gambar, atau pilih dokumen PDF hasil lab untuk mendapatkan penjelasan instan dalam bahasa yang mudah dimengerti.',
      'home_upload_button': 'Foto Hasil Lab',
      'home_take_photo_button': 'Kamera',
      'home_pick_gallery_button': 'Galeri',
      'home_pick_pdf_button': 'Upload Dokumen PDF',
      'home_selected_image': 'Gambar lab terpilih',
      'home_selected_document': 'Dokumen lab terpilih',
      'home_analyze_button': 'Analisis dengan AI',
      'home_analyzing_button': 'Menganalisis...',
      'home_analyze_trial_exhausted_button': 'Free Trial Habis',
      'home_analysis_result_title': 'Hasil Analisis AI',
      'home_analysis_findings_label': 'Temuan utama',
      'home_analysis_recommendation_label': 'Rekomendasi',
      'home_analysis_next_steps_label': 'Langkah selanjutnya',
      'home_save_analysis_button': 'Simpan Hasil Analisis',
      'home_saving_analysis_button': 'Menyimpan...',
      'home_saved_analysis_button': 'Sudah Disimpan',
      'home_save_trial_exhausted_button': 'Free Trial Habis',
      'home_saved_title': 'Analisis tersimpan',
      'home_saved_message': 'Hasil analisis telah ditambahkan ke riwayat Anda.',
      'home_saved_dialog_title': 'Berhasil disimpan',
      'home_saved_dialog_message':
          'Hasil analisis Anda sudah tersimpan dan siap dilihat kembali di Riwayat.',
      'home_saved_dialog_open_history': 'Buka Riwayat',
      'home_trial_analysis_limit_title': 'Batas free trial tercapai',
      'home_trial_analysis_limit_message':
          'Anda sudah menggunakan semua @max kali analisis gratis.',
      'home_trial_save_limit_title': 'Batas free trial tercapai',
      'home_trial_save_limit_message':
          'Anda sudah menggunakan semua @max kali simpan gratis.',
      'home_pick_failed_title': 'Gagal memilih gambar',
      'home_pick_failed_message':
          'Tidak dapat membaca gambar yang dipilih. Coba lagi.',
      'home_file_too_large_title': 'Ukuran file terlalu besar',
      'home_file_too_large_message':
          'Ukuran dokumen maksimal 500 KB. Silakan upload file yang lebih kecil.',
      'home_pdf_only_title': 'Tipe file tidak valid',
      'home_pdf_only_message': 'Silakan pilih dokumen PDF (.pdf).',
      'home_picker_unavailable_title': 'Pemilih file tidak tersedia',
      'home_picker_unavailable_message':
          'Plugin pemilih file belum siap. Silakan restart penuh aplikasi lalu coba lagi.',
      'home_file_size_label': 'Ukuran file: @size',
      'home_file_compressed_note': 'Dikompres dari @before menjadi @after.',
      'home_preparing_document':
          'Mengoptimalkan dokumen agar sesuai batas 500 KB...',
      'home_preparing_document_short': 'Mengoptimalkan...',
      'home_preparing_wait_title': 'Mohon tunggu',
      'home_preparing_wait_message': 'Proses optimasi dokumen masih berjalan.',
      'home_no_image_title': 'Belum ada gambar',
      'home_no_image_message':
          'Silakan ambil foto atau upload gambar hasil lab terlebih dahulu.',
      'home_no_document_title': 'Belum ada dokumen',
      'home_no_document_message':
          'Silakan ambil foto, upload, atau pilih dokumen hasil lab terlebih dahulu.',
      'home_analyze_failed_title': 'Analisis gagal',
      'home_analyze_failed_message':
          'Belum bisa menganalisis gambar saat ini. Coba lagi.',
      'home_save_failed_title': 'Gagal menyimpan',
      'home_save_failed_message':
          'Tidak dapat menyimpan hasil analisis. Coba lagi.',
      'home_save_failed_no_user': 'Sesi pengguna tidak tersedia. Coba lagi.',
      'home_summary_warning':
          'Beberapa indikator mungkin perlu perhatian berdasarkan gambar lab ini.',
      'home_summary_improve':
          'Indikator Anda menunjukkan tanda perbaikan dibanding pola umum.',
      'home_summary_normal':
          'Sebagian besar indikator yang terlihat berada dalam pola rentang yang diharapkan.',
      'home_recommendation_warning':
          'Konsultasikan dengan tenaga medis untuk konfirmasi dan langkah berikutnya.',
      'home_recommendation_improve':
          'Pertahankan kebiasaan sehat saat ini dan lanjutkan pemantauan tren.',
      'home_recommendation_normal':
          'Pertahankan pola makan seimbang dan aktivitas rutin, lalu cek ulang berkala.',
      'home_status_warning': 'Perhatian',
      'home_status_improve': 'Membaik',
      'home_status_normal': 'Stabil',
      'home_featured_title': 'Fitur unggulan',
      'home_feature_1_title': 'Scan & analisis instan',
      'home_feature_1_subtitle':
          'Foto hasil lab darah, urine, kolesterol, dan lihat ringkasan otomatis dalam hitungan detik.',
      'home_feature_2_title': 'Penjelasan sederhana',
      'home_feature_2_subtitle':
          'Pahami arti angka hasil lab Anda dengan bahasa awam.',
      'home_feature_3_title': 'Pantau tren kesehatan',
      'home_feature_3_subtitle':
          'Simpan riwayat tes dan lihat perkembangan indikator kesehatan dari waktu ke waktu.',
      'home_feature_4_title': 'Saran gaya hidup personal',
      'home_feature_4_subtitle':
          'Dapatkan rekomendasi aktivitas fisik dan pola makan berdasarkan hasil lab Anda.',
      'home_feature_5_title': 'Privasi terjamin',
      'home_feature_5_subtitle':
          'Data medis Anda aman dan terenkripsi untuk menjaga kerahasiaan informasi pribadi.',
      'home_sample_insight_button': 'Lihat Contoh Analisis',
      'home_disclaimer':
          'FitScript AI bukan pengganti saran, diagnosis, atau perawatan medis profesional. Selalu konsultasikan hasil laboratorium kepada dokter atau tenaga medis berwenang sebelum mengambil keputusan medis.',
      'home_upload_snackbar_title': 'Fitur upload',
      'home_upload_snackbar_message':
          'Siap untuk integrasi kamera / galeri dokumen lab.',
      'home_sample_insight_title': 'Contoh analisis',
      'home_sample_insight_message':
          'Hemoglobin sedikit di bawah normal. Pertimbangkan pola makan kaya zat besi dan tetap konfirmasi dengan dokter Anda.',
      'profile_title_account_subscription': 'Akun & Langganan',
      'profile_subscription_status': 'Status Langganan',
      'profile_subscription_free_plan': 'Paket Gratis',
      'profile_subscription_premium_plan': 'Premium (FitScript Pro)',
      'profile_subscription_description':
          'Upgrade untuk membuka semua fitur dan menghapus batas trial.',
      'profile_subscription_premium_description':
          'Premium aktif. Anda mendapatkan akses penuh untuk analisis dan simpan hasil.',
      'profile_trial_usage': 'Penggunaan Trial',
      'profile_trial_unlimited_message':
          'Akses tanpa batas aktif untuk analisis dan simpan hasil.',
      'profile_trial_left': '@count tersisa',
      'profile_trial_lab_result_analysis': 'Analisis Hasil Lab',
      'profile_trial_save_analysis_result': 'Simpan Hasil Analisis',
      'profile_privacy_policy': 'Kebijakan Privasi',
      'profile_terms_conditions': 'Syarat dan Ketentuan',
      'profile_danger_zone': 'Zona Berbahaya',
      'profile_danger_zone_description':
          'Hapus akun dan semua data terkait di Firestore. Tindakan ini tidak dapat dibatalkan. Jika Firebase meminta login ulang, lakukan autentikasi ulang menggunakan tombol di atas.',
      'profile_upgrade_button': 'Upgrade ke Premium',
      'profile_restore_button': 'Pulihkan Pembelian',
      'profile_sign_out_button': 'Keluar',
      'profile_sign_out_confirm_title': 'Keluar sekarang?',
      'profile_sign_out_confirm_message':
          'Anda akan melanjutkan sebagai akun tamu di perangkat ini.',
      'profile_sign_out_failed_title': 'Gagal keluar',
      'profile_sign_out_failed_message':
          'Terjadi kendala saat mencoba keluar akun. Coba lagi.',
      'profile_upgrade_info_title': 'Upgrade ke Premium',
      'profile_upgrade_info_message':
          'Alur upgrade premium akan tersedia di versi berikutnya.',
      'premium_title': 'Upgrade ke Premium',
      'premium_plan_name': 'Premium (FitScript Pro)',
      'premium_subtitle':
          'Buka semua kemampuan untuk keluarga dan pemantauan kesehatan jangka panjang.',
      'premium_feature_scan_title': 'Unlimited Scanning',
      'premium_feature_scan_subtitle':
          'Cocok untuk keluarga atau lansia dengan banyak laporan.',
      'premium_feature_insight_title': 'Deep Insight',
      'premium_feature_insight_subtitle':
          'AI tidak hanya menjelaskan, tetapi memberi saran nutrisi dan olahraga yang sangat mendetail.',
      'premium_feature_trend_title': 'Trend Analysis',
      'premium_feature_trend_subtitle':
          'Grafik perbandingan hasil lab dari waktu ke waktu, misalnya progres kolesterol selama 1 tahun.',
      'premium_feature_export_title': 'Export to PDF',
      'premium_feature_export_subtitle':
          'Laporan rangkuman rapi yang siap dibawa ke dokter.',
      'premium_pricing_title': 'Harga (Dynamic Pricing)',
      'premium_pricing_market_id': 'Indonesia',
      'premium_pricing_market_global': 'Global',
      'premium_price_id_monthly': 'Rp 29.000 / bulan',
      'premium_price_id_yearly': 'Rp 199.000 / tahun',
      'premium_price_global_monthly': '\$4.99 / bulan',
      'premium_price_global_yearly': '\$39.99 / tahun',
      'premium_pricing_note':
          'Paket yang ditampilkan dapat menyesuaikan locale dan region app store Anda.',
      'premium_cta_upgrade': 'Upgrade Sekarang',
      'profile_restore_info_title': 'Pulihkan Pembelian',
      'profile_restore_info_message':
          'Pemulihan pembelian belum tersedia pada versi ini.',
      'profile_user_default': 'Pengguna FitScript AI',
      'profile_user_not_connected': 'Belum terhubung dengan akun',
      'profile_language': 'Bahasa',
      'profile_language_changed': 'Bahasa diperbarui',
      'profile_language_changed_message':
          'Bahasa aplikasi diubah ke @language.',
      'profile_language_english': 'Inggris',
      'profile_language_indonesian': 'Indonesia',
      'profile_cancel': 'Batal',
      'profile_close': 'Tutup',
      'profile_account_sync_title': 'Sinkronisasi Akun',
      'profile_account_sync_anonymous':
          'Hubungkan akun Anda agar resep, chat, dan data langganan tersinkron di semua perangkat.',
      'profile_account_sync_connected':
          'Terhubung sebagai @name. Data Anda tersinkron di semua perangkat.',
      'profile_connect_google': 'Hubungkan dengan Google',
      'profile_connect_apple': 'Hubungkan dengan Apple',
      'profile_connecting': 'Menghubungkan...',
      'profile_delete_title': 'Hapus akun?',
      'profile_delete_message':
          'Semua data akun akan dihapus permanen dan tidak dapat dipulihkan.',
      'profile_delete_button': 'Hapus',
      'profile_deleting': 'Menghapus...',
      'profile_delete_success_title': 'Akun dihapus',
      'profile_delete_success_message':
          'Akun berhasil dihapus. Anda masuk kembali sebagai tamu.',
      'profile_delete_recent_login_title': 'Perlu login ulang',
      'profile_delete_recent_login_message':
          'Silakan autentikasi ulang lewat Google/Apple lalu coba hapus lagi.',
      'profile_delete_cancelled_title': 'Dibatalkan',
      'profile_delete_cancelled_message':
          'Proses autentikasi ulang dibatalkan.',
      'profile_delete_failed_title': 'Gagal hapus akun',
      'profile_delete_failed_message': 'Terjadi kendala saat menghapus akun.',
      'profile_delete_failed_message_with_code':
          'Terjadi kendala saat menghapus akun (@code).',
      'profile_delete_error_message':
          'Terjadi error saat proses hapus akun. Coba lagi.',
      'profile_link_success_title': 'Akun terhubung',
      'profile_link_success_message': 'Akun @provider berhasil dihubungkan.',
      'profile_login_success_title': 'Masuk berhasil',
      'profile_login_success_message':
          'Akun @provider sudah terhubung dan berhasil digunakan untuk masuk.',
      'profile_link_google_failed_title': 'Gagal link Google',
      'profile_link_google_failed_message':
          'Terjadi kendala saat menghubungkan akun Google.',
      'profile_link_apple_failed_title': 'Gagal link Apple',
      'profile_link_apple_failed_message':
          'Terjadi kendala saat menghubungkan akun Apple.',
      'profile_auth_error_different_credential':
          'Akun sudah terdaftar dengan metode lain. Silakan gunakan metode yang benar.',
      'profile_auth_error_invalid_credential':
          'Kredensial tidak valid. Coba ulangi proses masuk.',
      'profile_auth_error_apple_invalid':
          'Apple sign-in mengembalikan respons tidak valid. Pastikan Apple ID sudah login di perangkat ini lalu coba lagi.',
      'profile_auth_error_apple_setup':
          'Token Apple sign-in tidak tersedia. Pastikan Sign in with Apple sudah aktif di Apple Developer dan Firebase Console.',
      'profile_auth_error_generic':
          'Terjadi kendala autentikasi. Silakan coba lagi.',
    },
  };
}
