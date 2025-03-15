import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// Service for handling currency exchange operations
class ForexService {
  static final ForexService _instance = ForexService._internal();
  final Logger _logger = Logger('ForexService');
  
  // Exchange rate API configuration
  static const String _exchangeRateApiBaseUrl = 'https://api.exchangerate.host/convert';
  
  // Cache exchange rates to reduce API calls
  final Map<String, Map<String, double>> _rateCache = {};
  DateTime _lastCacheUpdate = DateTime(2000); // Initialize with old date
  static const Duration _cacheDuration = Duration(hours: 6); // Cache for 6 hours
  
  // Common currencies
  static const List<String> commonCurrencies = [
    'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'NZD', 'CHF', 'CNY', 'INR', 'NIS'
  ];

  // Private constructor for singleton
  ForexService._internal();
  
  // Getter for singleton instance
  factory ForexService() => _instance;

  /// Get exchange rate between two currencies
  Future<double> getExchangeRate(String fromCurrency, String toCurrency) async {
    // If same currency, return 1.0
    if (fromCurrency == toCurrency) {
      return 1.0;
    }
    
    // Check cache first
    if (_shouldUseCache()) {
      final cacheRate = _getCachedRate(fromCurrency, toCurrency);
      if (cacheRate != null) {
        return cacheRate;
      }
    }
    
    try {
      final response = await http.get(Uri.parse(
        '$_exchangeRateApiBaseUrl?from=$fromCurrency&to=$toCurrency&amount=1'
      ));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final rate = data['result'] as double;
          
          // Cache the result
          _cacheRate(fromCurrency, toCurrency, rate);
          
          return rate;
        }
      }
      
      // If API call fails, try to use fallback rates
      return _getFallbackRate(fromCurrency, toCurrency);
    } catch (e) {
      _logger.warning('Error fetching exchange rate: $e');
      return _getFallbackRate(fromCurrency, toCurrency);
    }
  }
  
  /// Convert amount from one currency to another
  Future<double> convertCurrency(double amount, String fromCurrency, String toCurrency) async {
    final rate = await getExchangeRate(fromCurrency, toCurrency);
    return amount * rate;
  }
  
  /// Check if we should use cached rates
  bool _shouldUseCache() {
    final now = DateTime.now();
    return now.difference(_lastCacheUpdate) < _cacheDuration;
  }
  
  /// Get a cached rate if available
  double? _getCachedRate(String fromCurrency, String toCurrency) {
    if (_rateCache.containsKey(fromCurrency) && 
        _rateCache[fromCurrency]!.containsKey(toCurrency)) {
      return _rateCache[fromCurrency]![toCurrency];
    }
    return null;
  }
  
  /// Cache an exchange rate
  void _cacheRate(String fromCurrency, String toCurrency, double rate) {
    // Update last cache time
    _lastCacheUpdate = DateTime.now();
    
    // Create map for from currency if it doesn't exist
    if (!_rateCache.containsKey(fromCurrency)) {
      _rateCache[fromCurrency] = {};
    }
    
    // Store the direct rate
    _rateCache[fromCurrency]![toCurrency] = rate;
    
    // Also store the inverse rate
    if (!_rateCache.containsKey(toCurrency)) {
      _rateCache[toCurrency] = {};
    }
    _rateCache[toCurrency]![fromCurrency] = 1.0 / rate;
  }
  
  /// Get a fallback rate if API fails
  double _getFallbackRate(String fromCurrency, String toCurrency) {
    // Fallback rates to USD (approximate values, should be updated)
    final Map<String, double> fallbackRatesToUSD = {
      'USD': 1.0,
      'EUR': 1.1,
      'GBP': 1.3,
      'JPY': 0.0091,
      'CAD': 0.75,
      'AUD': 0.67,
      'NZD': 0.61,
      'CHF': 1.12,
      'CNY': 0.14,
      'INR': 0.012,
      'NIS': 0.27,
    };
    
    // Convert through USD if both currencies are in the fallback list
    if (fallbackRatesToUSD.containsKey(fromCurrency) && 
        fallbackRatesToUSD.containsKey(toCurrency)) {
      final fromToUSD = fallbackRatesToUSD[fromCurrency]!;
      final usdToTarget = 1.0 / fallbackRatesToUSD[toCurrency]!;
      return fromToUSD * usdToTarget;
    }
    
    // Default to 1.0 if conversion isn't possible
    _logger.warning('Using default rate 1.0 for $fromCurrency to $toCurrency');
    return 1.0;
  }
  
  /// Fetch all exchange rates for commonly used currencies
  Future<void> preloadCommonRates() async {
    _logger.info('Preloading common exchange rates');
    
    for (var baseCurrency in commonCurrencies) {
      for (var targetCurrency in commonCurrencies) {
        if (baseCurrency != targetCurrency) {
          await getExchangeRate(baseCurrency, targetCurrency);
        }
      }
    }
    
    _logger.info('Finished preloading exchange rates');
  }
}