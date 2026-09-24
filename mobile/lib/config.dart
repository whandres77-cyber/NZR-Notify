class AppConfig {
  // Enquanto o backend de produção ainda não está publicado,
  // o app entra diretamente no modo demonstração e nunca trava na splash.
  static const bool demoMode = true;

  // Quando o backend estiver online, altere demoMode para false
  // e use aqui a URL HTTPS real do Railway.
  static const apiBaseUrl = 'http://10.0.2.2:8080';

  static const Duration apiTimeout = Duration(seconds: 4);
}
