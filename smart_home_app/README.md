# smart_home_app

# Flujo de accion del programa

1. Inicio de sesion, logica en `login_screen.dart`. Estoy usando la SignInScreen de firebase asi que se encarga solo de mostrar la pantalla y registrarlo en la base de datos. Desde el app_router detecto que cuando hay un usuario registrado pase directamente a home screen
2. Registrar network: Al entrar a home va a llamar en su initialize a findAndSaveRouterId en `providers.dart`. Se fija si hay algun valor cargado en el provider. Si no: Se hace una primer busqueda en todas las redes a ver si hay alguna red asociada al id del usuario. Si la detecta guardo la redId en un provider. Si no detecta que ya hay una network asociada al usuario, le pide que indique el id, una vez lo hace:
   - Registra el id del usuario en el apartado Users de la network indicada
   - Cambia `Connected` a true
   - Guarda en un provider el dato de Devices de la base de datos (id de cada modulo)
   - Guarda en un provider el id de la network
3. En homeScreen se ven datos tanto del aire como de las luces
4. Entrar a luces o a aire acondicionado, ahi se buildea primero el appbar en `device_appbar.dart`.

`Si nos quedamos con lo tuyo fran, entonces la logica de agregar/eliminar modulo que tengo en device_appbar la deberia borrar xq es al pedo`

## device_appbar

1. Llama a fetch devices, adentro busca la redId del provider y busca todos los modulos (luz o aire, dependiendo de a que pantalla entró) cuyo dato de network sea la redId
2. Setea como selectedDevice (el dispositivo que va a estar mostrando y se selecciona arriba) el primero de la DropdownButton, este va a tener como value la id del modulo y como nombre el `name` del modulo.
3. Al eliminar dispositivo lo busca dentro de la collection especificada y le hace remove. Y vuelve a llamar a fetch devices para actualizar
4. Al agregar dispositivo se indican los datos solicitados. Los que no se solicitan, se ponen en un valor por default.
   `borrar el agregar dispositivo, va a estar en la pantalla nueva, agregar el de info del dispositivo`
5. luz
6. aire
7. Al agregar dispositivo, se checkea si hay otro perteneciente a la red que tenga el mismo nombre. Sino, lo agrega y vuelve a llamar a fetch devices para actualizar

<TODO pagina de perfil, ver bien el tema de la imagen>

## aire acondicionado

Pepo solo maneja:

- Prendido frio
- Prendido caliente
- Apagado

Solo eso puede mandarle al aire, el resto (temperatura, fan, etc. va a ser solo visual para que el usuario se acuerde como lo configuró desde el control)

El tiempo de prendido y apagado lo maneja cami
