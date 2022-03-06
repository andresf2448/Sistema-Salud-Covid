// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

contract OMS_Covid{
    //Direccion de la OMS ---> owner
    address public OMS;

    constructor() {
        OMS = msg.sender;
    }

    //Mapping para relacionar los centros de salud con la validez del sistema de gestion
    mapping(address => bool) public validacionCentrosSalud;

    //Relacionar direccion de un cento de salud con su contrato
    mapping(address => address) public centroSaludContrato;

    //Array de direcciones que almacene los contratos de los centros de salud alidados
    address[] public direccionesContratosSalud;

    //Array de las direcciones que soliciten acceso
    address[] solicitudes;

    //Eventos a emitir
    event nuevoCentroValidado(address);
    event nuevoContrato(address, address);
    event solicitudAcceso(address);

    //Modificador que permita unicamnete la ejecucion de funciones por la OMS
    modifier unicamenteOMS(address _direccion){
        require(_direccion == OMS, "No tienes permisos para realizar esta funcion.");
        _;
    }

    //Funcion para validar nuevos centros de salud que puedan autogestionarse --> unicamneteOMS
    function centroSalud(address _centroSalud) public unicamenteOMS(msg.sender){
        //Asignacion del estado de validez al centro de salud
        validacionCentrosSalud[_centroSalud] = true;

        emit nuevoCentroValidado(_centroSalud);
    }

    //Funcion para solicitar acceso al sistema medico
    function solicitarAcceso() public {
        //Almacenar la direccion en el array de solicitudes
        solicitudes.push(msg.sender);

        emit solicitudAcceso(msg.sender);
    }

    //Funcion para visualizar las direcciones que han solicitado este acceso
    function visualizarSolicitudes() public view unicamenteOMS(msg.sender) returns(address[] memory){
        return solicitudes;
    }

    //Funcion que permita crear un contrato inteligente de un centro de salud
    function factoryCentroSalud() public {
        //unicamente los centros de salud validados pueden ejecutar esta funcion
        require(validacionCentrosSalud[msg.sender] == true, "No tienes los permisos necesarios.");
        //generamos un smart contract
        address contratoCentroSalud = address(new CentroSalud(msg.sender));
        //Almacenamiento de la direccion del contrato en el array
        direccionesContratosSalud.push(contratoCentroSalud);
        //Relacion entre el centro de salud y su contrato
        centroSaludContrato[msg.sender] = contratoCentroSalud;
        
        emit nuevoContrato(contratoCentroSalud, msg.sender);
    }
}

//Contrato autogestionable por el centro de salud
contract CentroSalud{
    address public direccionCentroSalud;
    address public direccionContrato;

    constructor(address _direccion){
        direccionCentroSalud = _direccion;
        direccionContrato = address(this);
    }

   //Mapping para relacionar el hash de la persona con los resultados (diagnostico, codigo ipfs
    mapping (bytes32 => Resultados) resultadosCovid;

    //estructura de los resultados
    struct Resultados {
        bool diagnostico;
        string codigoIpfs;
    }

    //Events
    event nuevoResultado(bool, string);

    //filtrar las funciones a ejecutar por el centro de salud
    modifier unicamenteCentroSalud(address _direccion) {
        require(_direccion == direccionCentroSalud, "No tienes permisos para ejecutar esta funcion.");
        _;
    }

    //funcion para emitir un resultado de una prueba de covid
    function resultadosPruebaCovid(string memory _idPersona, bool _resultadoCovid, string memory _codigoIpfs) public unicamenteCentroSalud(msg.sender){
        //hash de identificacion de la persona
        bytes32 hashIdPersona = keccak256(abi.encodePacked(_idPersona));
        //relacion del hash de la mpersona con la estructura de resultados
        resultadosCovid[hashIdPersona] = Resultados(_resultadoCovid, _codigoIpfs);

        emit nuevoResultado(_resultadoCovid, _codigoIpfs);
    }

    //funcion que permita la visualizacion de los resultados
    function visualizarResultados(string memory _idPersona)public view returns(string memory _resultadoPrueba, string memory _codigoIpfs){
        //hash de la identidad de la persona
        bytes32 hashIdPersona = keccak256(abi.encodePacked(_idPersona));

        string memory resultadoPrueba;

        if(resultadosCovid[hashIdPersona].diagnostico == true){
            resultadoPrueba = "Positivo";
        }else{
            resultadoPrueba = "Negativo";
        }

        _resultadoPrueba = resultadoPrueba;
        _codigoIpfs = resultadosCovid[hashIdPersona].codigoIpfs;
    }
}