import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../mock/weather_mock.dart';
import '../details/weather_details.dart';
import '../../mock//brazilian_states.dart';

class WeatherFeedScreen extends StatefulWidget {
  const WeatherFeedScreen({super.key});

  @override
  State<WeatherFeedScreen> createState() => _WeatherFeedScreenState();
}

class _WeatherFeedScreenState extends State<WeatherFeedScreen> {
  bool isLoggedIn = false;
  bool isFavorite = false;
  final ScrollController _scrollController = ScrollController();
  bool isLoading = false;
  List<Map<String, dynamic>> weatherLazyData = [];
  int lastLoadedIndex = 6;
  String selectedState = 'Todos';

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

  Future<void> googleSignIn() async {
    await _googleSignIn.signIn().then((value) {
      if (value != null) {
        userNameGoogle = value.displayName?.split(' ')[0];
        userEmailGoogle = value.email;
        setState(() {
          isLoggedIn = true;
        });
      }
    });
  }

  Future<void> googleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.blue,
          child: const Center(
            child: Text(
              'Confirmar Logout',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        content: const Text(
          'Tem certeza de que deseja sair?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _googleSignIn.signOut();
              setState(() {
                isLoggedIn = false;
                userNameGoogle = '';
                userEmailGoogle = '';
                isFavorite = false;
                selectedState = 'Todos';
                for (var weather in weatherLazyData) {
                  weather['favorite'] = false;
                }
              });
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

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

  void _showLoginPopup(String reason) {
    String message;
    if (reason == 'listfavorites') {
      message = 'Para exibir seus favoritos, faça login.';
    } else if (reason == 'favoritecity') {
      message = 'Para salvar cidades favoritas, faça login.';
    } else {
      message = 'Ação requer login.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.blue,
          child: const Center(
            child: Text(
              'Login requerido',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              await googleSignIn();
              if (isLoggedIn) {
                Navigator.pop(context);
              }
            },
            child: const Text('Fazer Login'),
          ),
        ],
      ),
    );
  }

  void _handleFavorite(String city, Map<String, dynamic> weather) {
    if (isLoggedIn) {
      setState(() {
        weather['favorite'] = !(weather['favorite'] ?? false);
        String message = weather['favorite']
            ? '$city foi adicionada aos favoritos!'
            : '$city foi removida dos favoritos!';
        Color backgroundColor = weather['favorite'] ? Colors.green : Colors.red;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    } else {
      _showLoginPopup('favoritecity');
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
    final List<Map<String, dynamic>> filteredData = isFavorite
        ? weatherLazyData
            .where((weather) => weather['favorite'] == true)
            .toList()
        : weatherLazyData
            .where((weather) =>
                selectedState == 'Todos' || weather['state'] == selectedState)
            .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        elevation: 4,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    if (!isLoggedIn) {
                      _showLoginPopup('listfavorites');
                    } else {
                      setState(() {
                        isFavorite = !isFavorite;
                        selectedState = 'Todos';
                      });
                    }
                  },
                ),
                if (isLoggedIn)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      "Olá, $userNameGoogle!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                if (isLoggedIn)
                  Row(
                    children: [
                      const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 24.0,
                      ),
                      TextButton(
                        onPressed: googleLogout,
                        child: const Text(
                          "Sair",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (!isLoggedIn)
                  Row(
                    children: [
                      const Icon(
                        Icons.login,
                        color: Colors.white,
                        size: 24.0,
                      ),
                      TextButton(
                        onPressed: googleSignIn,
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!isFavorite)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8.0),
                          topRight: Radius.circular(8.0),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 16.0),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.filter_alt,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8.0),
                          Text(
                            'Selecione o Estado:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: DropdownButton<String>(
                        value: selectedState,
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedState = newValue!;
                          });
                        },
                        items: brazilianStates
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: filteredData.isEmpty
                ? Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isFavorite
                              ? 'Sem favoritos no momento'
                              : 'Nenhum resultado para o estado selecionado',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.search_off,
                          color: Colors.grey,
                          size: 24,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredData.length,
                    controller: _scrollController,
                    itemBuilder: (context, index) {
                      final weather = filteredData[index];
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        weather['city'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      Text(
                                        '${weather['weather']} - ${weather['temperature']}°C',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
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
                                  icon: Icon(
                                    weather['favorite'] == true
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () =>
                                      _handleFavorite(weather['city'], weather),
                                )
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
