import 'package:flutter/material.dart';
import 'package:flutter_application_movile/domain/entities/mensaje_chat_entity.dart';
import 'package:flutter_application_movile/domain/entities/lugar_entity.dart';

class MensajeChatWidget extends StatelessWidget {
  final MensajeChatEntity mensaje;
  final Function(LugarEntity)? onPlaceTap;
  final List<LugarEntity>? lugares;

  const MensajeChatWidget({
    super.key, 
    required this.mensaje,
    this.onPlaceTap,
    this.lugares,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = mensaje.esUsuario;
    final bubbleColor = isUser ? Colors.white : Theme.of(context).colorScheme.primary.withOpacity(0.10);
    final labelColor = isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary;

    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
          border: isUser ? Border.all(color: Colors.grey.shade200) : null,
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
            if (mensaje.tipoLugar != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: labelColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  mensaje.tipoLugar!,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              mensaje.contenido,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            
            // Enhanced place recommendations with tap-to-center functionality
            if (!isUser && lugares != null && lugares!.isNotEmpty) ...[
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
              ...lugares!.asMap().entries.map((entry) {
                final index = entry.key;
                final lugar = entry.value;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onPlaceTap?.call(lugar),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
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
                              _getPlaceIcon(lugar.tipoLugar),
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
                                    lugar.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (lugar.direccion.isNotEmpty)
                                    Text(
                                      lugar.direccion,
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
                            
                            // Tap indicator
                            Icon(
                              Icons.location_on,
                              color: Colors.grey.shade400,
                              size: 16,
                            ),
                          ],
                        ),
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
        return Icons.park;
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