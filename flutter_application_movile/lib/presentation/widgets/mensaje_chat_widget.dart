import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_movile/domain/entities/lugar_entity.dart';
import 'package:flutter_application_movile/domain/entities/mensaje_chat_entity.dart';
import 'package:flutter_application_movile/presentation/bloc/chat/chat_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class MensajeChatWidget extends StatefulWidget {
  final ChatMessageEntity message;
  final Function(PlaceEntity)? onPlaceTap;
  final List<PlaceEntity>? places;

  const MensajeChatWidget({
    super.key, 
    required this.message,
    this.onPlaceTap,
    this.places,
  });

  @override
  State<MensajeChatWidget> createState() => _MensajeChatWidgetState();
}

class _MensajeChatWidgetState extends State<MensajeChatWidget> {
  // Track recently-saved places to show a transient animated check
  final Set<String> _recentlySaved = <String>{};

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.esUsuario;
    final bubbleColor = isUser ? Colors.white : Theme.of(context).colorScheme.primary.withOpacity(0.10);
    final labelColor = isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary;

    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
          border: isUser ? Border.all(color: Colors.grey.shade200) : Border.all(color: Colors.deepPurple.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.message.placeType != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: labelColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.message.placeType!,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Texto del mensaje con formato simple de negrilla (**texto**)
            SelectableText.rich(
              TextSpan(children: _buildFormattedSpans(widget.message.contenido, Theme.of(context).textTheme.bodyLarge!)),
              textAlign: TextAlign.left,
            ),

            // Acciones rápidas para teléfonos y enlaces presentes en el contenido
            ..._buildQuickActions(widget.message.contenido),
            
            // Enhanced place recommendations with tap-to-center functionality
            if (!isUser && widget.places != null && widget.places!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                'Lugares recomendados:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.places!.asMap().entries.map((entry) {
                final index = entry.key;
                final place = entry.value;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.onPlaceTap?.call(place),
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Place number badge
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.deepPurple.shade400,
                                        Colors.purple.shade600,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                
                                // Place icon
                                Icon(
                                  _getPlaceIcon(place.placeType),
                                  color: Colors.deepPurple.shade600,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                
                                // Place details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        place.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (place.address.isNotEmpty)
                                        Text(
                                          place.address,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                
                                // Actions: center on map and save favorite
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Ver en mapa',
                                      icon: Icon(
                                        Icons.location_on,
                                        color: Colors.deepPurple.shade400,
                                      ),
                                      onPressed: () => widget.onPlaceTap?.call(place),
                                    ),
                                    if (place.phone != null && place.phone!.isNotEmpty) ...[
                                      IconButton(
                                        tooltip: 'Llamar',
                                        icon: const Icon(Icons.phone, color: Colors.green),
                                        onPressed: () {
                                          final tel = place.phone!.replaceAll(' ', '').replaceAll('-', '');
                                          launchUrl(Uri.parse('tel:$tel'));
                                        },
                                      ),
                                      IconButton(
                                        tooltip: 'Copiar número',
                                        icon: const Icon(Icons.copy, color: Colors.black87),
                                        onPressed: () async {
                                          await Clipboard.setData(ClipboardData(text: place.phone!));
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Número copiado al portapapeles')),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                    if (place.website != null && place.website!.isNotEmpty)
                                      IconButton(
                                        tooltip: 'Abrir sitio web',
                                        icon: const Icon(Icons.open_in_new, color: Colors.blue),
                                        onPressed: () {
                                          final url = place.website!;
                                          final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
                                          launchUrl(uri, mode: LaunchMode.externalApplication);
                                        },
                                      ),
                                    IconButton(
                                      tooltip: 'Guardar favorito',
                                      icon: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 200),
                                        child: _recentlySaved.contains(place.id)
                                            ? const Icon(Icons.favorite, key: ValueKey('fav'), color: Colors.pinkAccent)
                                            : const Icon(Icons.favorite_border, key: ValueKey('unfav'), color: Colors.pinkAccent),
                                      ),
                                      onPressed: () {
                                        final bloc = context.read<ChatBloc>();
                                        bloc.add(GuardarLugarFavoritoEvent(place));
                                        // Show animated check overlay
                                        setState(() {
                                          _recentlySaved.add(place.id);
                                        });
                                        Future.delayed(const Duration(milliseconds: 1200), () {
                                          if (!mounted) return;
                                          setState(() {
                                            _recentlySaved.remove(place.id);
                                          });
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Animated check overlay in the top-right corner
                          Positioned(
                            right: 8,
                            top: 8,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 250),
                              opacity: _recentlySaved.contains(place.id) ? 1 : 0,
                              child: AnimatedScale(
                                scale: _recentlySaved.contains(place.id) ? 1 : 0.8,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutBack,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade600,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.shade200,
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.check, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              
              // Helpful hint
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 12,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Toca un lugar para verlo en el mapa',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final avatar = CircleAvatar(
      backgroundColor: isUser ? Colors.grey.shade300 : Theme.of(context).colorScheme.primary,
      child: Icon(isUser ? Icons.person : Icons.smart_toy, color: isUser ? Colors.white : Colors.white),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isUser
            ? [
                Expanded(child: Align(alignment: Alignment.centerRight, child: bubble)),
                const SizedBox(width: 12),
                avatar,
              ]
            : [
                avatar,
                const SizedBox(width: 12),
                Expanded(child: bubble),
              ],
      ),
    );
  }

  // Convierte "**texto**" a negrilla y detecta URLs/teléfonos como spans clicables
  List<TextSpan> _buildFormattedSpans(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];

    // Helper para añadir segmentos que pueden contener URLs/teléfonos dentro
    void addSegment(String segment, {bool bold = false}) {
      final urlRegex = RegExp(r'(https?:\/\/[^\s)]+)');
      final phoneRegex = RegExp(r'(\+?[0-9][0-9\s\-]{6,}[0-9])');

      int index = 0;
      while (index < segment.length) {
        final urlMatch = urlRegex.matchAsPrefix(segment, index);
        final phoneMatch = phoneRegex.matchAsPrefix(segment, index);

        if (urlMatch != null) {
          final urlText = urlMatch.group(0)!;
          // Render azul subrayado para indicar enlace; acciones se ofrecen vía chips.
          spans.add(TextSpan(
            text: urlText,
            style: baseStyle.copyWith(
              color: Colors.blue,
              decoration: TextDecoration.underline,
              fontWeight: bold ? FontWeight.w700 : baseStyle.fontWeight,
            ),
          ));
          index = urlMatch.end;
        } else if (phoneMatch != null) {
          final phoneText = phoneMatch.group(0)!.trim();
          // Render azul subrayado para indicar teléfono; acciones se ofrecen vía chips.
          spans.add(TextSpan(
            text: phoneText,
            style: baseStyle.copyWith(
              color: Colors.blue,
              decoration: TextDecoration.underline,
              fontWeight: bold ? FontWeight.w700 : baseStyle.fontWeight,
            ),
          ));
          index = phoneMatch.end;
        } else {
          // Texto normal
          spans.add(TextSpan(
            text: segment[index],
            style: baseStyle.copyWith(fontWeight: bold ? FontWeight.w700 : baseStyle.fontWeight),
          ));
          index++;
        }
      }
    }

    // Parseo simple de **negrilla**
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1; // los índices impares están entre ** **
      addSegment(parts[i], bold: isBold);
    }

    return spans;
  }

  // Construye chips de acción para copiar teléfonos y abrir enlaces
  List<Widget> _buildQuickActions(String text) {
    final urlRegex = RegExp(r'(https?:\/\/[^\s)]+)');
    final phoneRegex = RegExp(r'(\+?[0-9][0-9\s\-]{6,}[0-9])');

    final urls = urlRegex.allMatches(text).map((m) => m.group(0)!).toList();
    final phones = phoneRegex.allMatches(text).map((m) => m.group(0)!.trim()).toList();

    final widgets = <Widget>[];

    if (phones.isNotEmpty || urls.isNotEmpty) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...phones.map((p) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActionChip(
                    label: Text('Llamar $p'),
                    avatar: const Icon(Icons.phone, size: 16),
                    onPressed: () {
                      final uri = Uri.parse('tel:${p.replaceAll(' ', '').replaceAll('-', '')}');
                      launchUrl(uri);
                    },
                  ),
                  IconButton(
                    tooltip: 'Copiar número',
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: p));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Número copiado al portapapeles')),
                        );
                      }
                    },
                  ),
                ],
              )),
          ...urls.map((u) => ActionChip(
                label: const Text('Abrir enlace'),
                avatar: const Icon(Icons.link, size: 16),
                onPressed: () {
                  launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
                },
              )),
        ],
      ));
    }

    return widgets;
  }

  // Helper method to get appropriate icon for place type
  IconData _getPlaceIcon(String? tipo) {
    if (tipo == null) return Icons.place;
    
    switch (tipo.toLowerCase()) {
      case 'restaurant':
      case 'restaurante':
      case 'food':
      case 'comida':
        return Icons.restaurant;
      case 'hotel':
      case 'lodging':
      case 'hospedaje':
        return Icons.hotel;
      case 'tourist_attraction':
      case 'attraction':
      case 'atraccion':
      case 'turismo':
        return Icons.camera_alt;
      case 'shopping_mall':
      case 'store':
      case 'tienda':
      case 'compras':
        return Icons.shopping_bag;
      case 'hospital':
      case 'health':
      case 'salud':
        return Icons.local_hospital;
      case 'gas_station':
      case 'gasolina':
        return Icons.local_gas_station;
      case 'bank':
      case 'atm':
      case 'banco':
        return Icons.account_balance;
      case 'park':
      case 'parque':
        return Icons.nature;
      case 'museum':
      case 'museo':
        return Icons.museum;
      case 'church':
      case 'iglesia':
        return Icons.church;
      default:
        return Icons.place;
    }
  }
}