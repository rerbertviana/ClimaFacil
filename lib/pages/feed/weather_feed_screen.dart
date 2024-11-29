import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../mock/weather_mock.dart';
import '../details/weather_details.dart';

class WeatherFeedScreen extends StatefulWidget {
  const WeatherFeedScreen({super.key});

  @override
  State<WeatherFeedScreen> createState() => _WeatherFeedScreenState();
}

class _WeatherFeedScreenState extends State<WeatherFeedScreen> {
  bool isLoggedIn = false;
  String userName = "Usuário";
  final ScrollController _scrollController = ScrollController();
  bool isLoading = false;
  List<Map<String, dynamic>> weatherLazyData = [];
  int lastLoadedIndex = 6;

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  String? userNameGoogle = "";
  String? userEmailGoogle = "";

  Future<void> _loadMoreItems() async {
    setState(() {
      isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      weatherLazyData.addAll(weatherMockData.skip(lastLoadedIndex).take(6));
      lastLoadedIndex = lastLoadedIndex + 6;
      if (lastLoadedIndex >= weatherMockData.length) {
        lastLoadedIndex = weatherMockData.length;
      }
      isLoading = false;
    });
  }

  Future<void> tryToGoogleLogin() async {
    await _googleSignIn.signIn().then((value) {
      userNameGoogle = value!.displayName;
      userEmailGoogle = value.email;
    });
    print("Deu certo! $userNameGoogle");
  }

  // void tryToGoogleLogin() {
  //   print("GOOGLE LOGIN");
  // }

  @override
  void initState() {
    super.initState();
    if (lastLoadedIndex == 6) {
      weatherLazyData = weatherMockData.take(6).toList();
    }
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        _loadMoreItems();
      }
    });
  }

  IconData getWeatherIcon(String weatherCondition) {
    switch (weatherCondition) {
      case 'Ensolarado':
        return Icons.wb_sunny;
      case 'Parcialmente Nublado':
        return Icons.cloud_off_outlined;
      case 'Nublado':
        return Icons.cloud_outlined;
      case 'Chuva':
        return Icons.grain;
      case 'Tempestade':
        return Icons.storm;
      case 'Neve':
        return Icons.ac_unit;
      case 'Vento':
        return Icons.air;
      case 'Frio':
        return Icons.ac_unit;
      default:
        return Icons.help_outline;
    }
  }

  void _showLoginPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.blue, // Caixa azul
          child: const Center(
            child: Text(
              'Login requerido',
              style: TextStyle(
                color: Colors.white, // Fonte branca
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        content: const Text(
          'Para salvar cidades favoritas, faça login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue, // Cor do texto branca
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Raio menor
              ),
            ),
            onPressed: tryToGoogleLogin,
            // onPressed: () {
            //   Navigator.pop(context);
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (context) => const LoginScreen()),
            //   );
            // },
            child: const Text('Fazer Login'),
          ),
        ],
      ),
    );
  }

  void _handleFavorite(String city) {
    if (isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$city foi adicionada aos favoritos!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _showLoginPopup();
    }
  }

  void _navigateToDetails(Map<String, dynamic> weatherDetails) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeatherDetailsScreen(details: weatherDetails),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: isLoggedIn
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Olá, $userName!"),
                  IconButton(
                    icon: const Icon(Icons.favorite),
                    onPressed: () {
                      if (!isLoggedIn) {
                        _showLoginPopup();
                      }
                    },
                  ),
                ],
              )
            : TextButton(
                onPressed: _showLoginPopup,
                child: const Text(
                  "Login",
                  style: TextStyle(color: Colors.white),
                ),
              ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: weatherLazyData.length,
              controller: _scrollController,
              itemBuilder: (context, index) {
                final weather = weatherLazyData[index];
                return GestureDetector(
                  onTap: () => _navigateToDetails(weather),
                  child: Card(
                    margin: const EdgeInsets.all(12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            getWeatherIcon(weather['weather']),
                            size: 60,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  weather['city'],
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                Text(
                                  '${weather['weather']} - ${weather['temperature']}°C',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      'Clique para mais detalhes',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.blue,
                                            fontSize: 14,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.touch_app,
                                      size: 24,
                                      color: Colors.blue,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.favorite_border,
                              color: Colors.blue,
                            ),
                            onPressed: () => _handleFavorite(weather['city']),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text('Tela de Login (Placeholder)'),
      ),
    );
  }
}
