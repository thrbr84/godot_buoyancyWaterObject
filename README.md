# godot-buoyancy-water-object

Godot 3.2

### Como usar a água
- Instale o addon Polygon2Dwater no seu projeto, habilite nas configurações e utilize o node "Polygon2Dwater" para simular e configurar sua água

### Como simular o efeito de objeto boiando
- Verifique o script do barco e da bola nos exemplo

### Para seu RigidBody2D
Quando seu objeto entra em contato com a água, a água tentar chamar essas duas funções no seu RigidBody2D

```python
func _on_water_entered(_agua, _altura, _tensao, _amortecimento):
    # implementar seu script
```

```python
func _on_water_exited():
    # implementar seu script
```


[![IMAGE ALT TEXT HERE](https://img.youtube.com/vi/2SPWcQss4Ls/0.jpg)](https://www.youtube.com/watch?v=2SPWcQss4Ls)

### ...
Vai utilizar esse código de forma comercial? Fique tranquilo pode usar de forma livre e sem precisar mencionar nada, claro que vou ficar contente se pelo menos lembrar da ajuda e compartilhar com os amigos, rs. Caso sinta no coração, considere me pagar um cafezinho :heart: -> https://ko-fi.com/thiagobruno

