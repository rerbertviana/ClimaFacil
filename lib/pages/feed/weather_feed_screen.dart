import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../details/weather_details.dart';
import '../../utils/brazilian_states.dart';

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
  bool isLoadingData = true;
  List<Map<String, dynamic>> weatherLazyData = [];
  List<Map<String, dynamic>> weatherData = [];
  int lastLoadedIndex = 6;
  String selectedState = 'Todos';
  final baseUrlWeathers = dotenv.env['API_URL_WEATHERS'];
  final baseUrlFavorites = dotenv.env['API_URL_FAVORITES'];
  final baseUrlUsers = dotenv.env['API_URL_USERS'];

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  String? userNameGoogle = "";
  String? userEmailGoogle = "";
  int? userId;

  Future<void> loadData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrlWeathers'));
      if (isLoggedIn) {
        try {
          final responseFavorites =
              await http.get(Uri.parse('$baseUrlFavorites/$userId'));
          if (responseFavorites.statusCode == 200) {
            List<Map<String, dynamic>> favoriteData =
                List<Map<String, dynamic>>.from(
                    jsonDecode(responseFavorites.body));
            Set<int> favoriteIds =
                favoriteData.map<int>((fav) => fav['weatherId'] as int).toSet();
            List<Map<String, dynamic>> updatedWeathers =
                weatherData.map((weather) {
              return {
                ...weather,
                'favorite': favoriteIds.contains(weather['id'])
              };
            }).toList();
            setState(() {
              weatherData = updatedWeathers;
              if (lastLoadedIndex == 6) {
                weatherLazyData = weatherData.take(6).toList();
              } else {
                weatherLazyData = weatherData.take(lastLoadedIndex).toList();
              }
            });
          }
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erro ao apresentar lista de climas!'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        if (response.statusCode == 200) {
          setState(() {
            weatherData =
                List<Map<String, dynamic>>.from(jsonDecode(response.body));
            if (lastLoadedIndex == 6) {
              weatherLazyData = weatherData.take(6).toList();
            } else {
              weatherLazyData = weatherData.take(lastLoadedIndex).toList();
            }
            isLoadingData = false;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao apresentar lista de climas!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreItems() async {
    setState(() {
      isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      weatherLazyData.addAll(weatherData.skip(lastLoadedIndex).take(6));
      lastLoadedIndex = lastLoadedIndex + 6;
      if (lastLoadedIndex >= weatherData.length) {
        lastLoadedIndex = weatherData.length;
      }
      isLoading = false;
    });
  }

  Future<void> googleSignIn() async {
    await _googleSignIn.signIn().then((value) async {
      if (value != null) {
        userNameGoogle = value.displayName?.split(' ')[0];
        userEmailGoogle = value.email;
        try {
          final response = await http.post(
            Uri.parse('$baseUrlUsers'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': userNameGoogle,
              'email': userEmailGoogle,
            }),
          );
          if (response.statusCode == 200) {
            final userData = jsonDecode(response.body);
            userId = userData['userId'];
          }
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao tentar realizar o login: $error'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        setState(() {
          isLoggedIn = true;
        });
        await loadData();
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
    loadData();
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
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              }
            },
            child: const Text('Fazer Login'),
          ),
        ],
      ),
    );
  }

  void _handleFavorite(String city, Map<String, dynamic> weather) async {
    if (isLoggedIn) {
      try {
        bool isFavorite = weather['favorite'] ?? false;
        if (isFavorite == true) {
          final response = await http.delete(
            Uri.parse('$baseUrlFavorites'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'userId': userId,
              'weatherId': weather['id'],
            }),
          );

          if (response.statusCode == 200) {
            await loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$city foi removida dos favoritos!'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erro ao remover favorito!'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } else {
          final response = await http.post(
            Uri.parse('$baseUrlFavorites'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'userId': userId,
              'weatherId': weather['id'],
            }),
          );

          if (response.statusCode == 201) {
            await loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$city foi adicionada aos favoritos!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erro ao adicionar favorito!'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao processar a solicitação!'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
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
        ? weatherData.where((weather) => weather['favorite'] == true).toList()
        : weatherData
            .where((weather) =>
                selectedState == 'Todos' ||
                weather['state'] != null && weather['state'] == selectedState)
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
                        onChanged: (String? newValue) async {
                          setState(() {
                            selectedState = newValue!;
                          });
                          await loadData();
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
          if (isLoadingData)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: CircularProgressIndicator(),
            ),
          Expanded(
            child: filteredData.isEmpty && isLoadingData == false
                ? Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isFavorite
                              ? 'Sem favoritos no momento'
                              : 'Nenhum resultado para o estado selecionado',
                          style: const TextStyle(
                            fontSize: 17,
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
