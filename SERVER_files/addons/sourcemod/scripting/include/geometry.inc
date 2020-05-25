#include <sourcemod>
#include <smlib>
#define x 0
#define y 1
#define z 2

#define A 0
#define B 1
#define C 2
#define D 3
#define E 4
#define F 5
#define G 6
#define H 7
#define I 8
#define L 9
#define M 10
#define N 11

stock void Geo_GetAxis(float center[3], float ampitude, float buffer[3][3])
{
	buffer[0][x] = center[x] + ampitude * 2;
	buffer[0][y] = center[y];
	buffer[0][z] = center[z];
	
	buffer[1][x] = center[x];
	buffer[1][y] = center[y] + ampitude * 2;
	buffer[1][z] = center[z];
	
	buffer[2][x] = center[x];
	buffer[2][y] = center[y];
	buffer[2][z] = center[z] + ampitude * 2;
}

stock void Geo_NewTriangle(float center[3], float ampitude, float buffer[3][3])
{
	float lato = ampitude * SquareRoot(3.0);
	float h = 3 / 2 / ampitude / 2;
	buffer[A][x] = center[x] - lato / 2;
	buffer[A][y] = center[y] - h / 2;
	
	buffer[B][x] = center[x] + lato / 2;
	buffer[B][y] = center[y] - h / 2;
	
	buffer[C][x] = center[x];
	buffer[C][y] = center[y] + h / 2;
}

stock void Geo_NewSquare(float center[3], float ampitude, float buffer[4][3])
{
	buffer[A][z] = center[z];
	buffer[B][z] = center[z];
	buffer[C][z] = center[z];
	buffer[D][z] = center[z];
	
	buffer[A][x] = center[x] - ampitude / 2;
	buffer[A][y] = center[y] + ampitude / 2;
	
	buffer[B][x] = center[x] - ampitude / 2;
	buffer[B][y] = center[y] - ampitude / 2;
	
	buffer[C][x] = center[x] + ampitude / 2;
	buffer[C][y] = center[y] - ampitude / 2;
	
	buffer[D][x] = center[x] + ampitude / 2;
	buffer[D][y] = center[y] + ampitude / 2;
}

stock void Geo_NewPentagon(float center[3], float ampitude, float buffer[5][3])
{
	buffer[A][z] = center[z];
	buffer[B][z] = center[z];
	buffer[C][z] = center[z];
	buffer[D][z] = center[z];
	buffer[E][z] = center[z];
	
	float apo = ampitude / 2 * (SquareRoot(5.0) + 1) / 4;
	float lato = ampitude / 2 * SquareRoot(10.0 - 2 * SquareRoot(5.0));
	float diagonale = lato * (SquareRoot(5.0) + 1.0) / 2;
	float pita = SquareRoot(Pow(ampitude / 2, 2.0) - Pow(diagonale / 2, 2.0));
	
	buffer[A][x] = center[x];
	buffer[A][y] = center[y] + ampitude / 2;
	
	buffer[C][x] = center[x] - lato / 2;
	buffer[C][y] = center[y] - apo;
	
	buffer[D][x] = center[x] + lato / 2;
	buffer[D][y] = center[y] - apo;
	
	buffer[B][x] = center[x] - diagonale / 2;
	buffer[B][y] = center[y] + pita;
	
	buffer[E][x] = buffer[B][x] + diagonale;
	buffer[E][y] = buffer[B][y];
}

stock void Geo_NewExagon(float center[3], float ampitude, float buffer[6][3])
{
	buffer[A][z] = center[z];
	buffer[B][z] = center[z];
	buffer[C][z] = center[z];
	buffer[D][z] = center[z];
	buffer[E][z] = center[z];
	buffer[F][z] = center[z];
	
	buffer[B][x] = center[x] - ampitude / 2;
	buffer[B][y] = center[y];
	
	buffer[A][x] = center[x] - ampitude / 4;
	buffer[A][y] = center[y] + ampitude / 2;
	
	buffer[C][x] = center[x] - ampitude / 4;
	buffer[C][y] = center[y] - ampitude / 2;
	
	buffer[D][x] = center[x] + ampitude / 4;
	buffer[D][y] = center[y] - ampitude / 2;
	
	buffer[E][x] = center[x] + ampitude / 2;
	buffer[E][y] = center[y];
	
	buffer[F][x] = center[x] + ampitude / 4;
	buffer[F][y] = center[y] + ampitude / 2;
}

//ETTAGONO?

stock void Geo_NewOctagon(float center[3], float ampitude, float buffer[8][3])
{
	buffer[A][z] = center[z];
	buffer[B][z] = center[z];
	buffer[C][z] = center[z];
	buffer[D][z] = center[z];
	buffer[E][z] = center[z];
	buffer[F][z] = center[z];
	buffer[G][z] = center[z];
	buffer[H][z] = center[z];
	
	buffer[B][x] = center[x] - ampitude / 2;
	buffer[B][y] = center[y] + ampitude / 4;
	
	buffer[A][x] = center[x] - ampitude / 4;
	buffer[A][y] = center[y] + ampitude / 2;
	
	buffer[C][x] = center[x] - ampitude / 2;
	buffer[C][y] = center[y] - ampitude / 4;
	
	buffer[D][x] = center[x] - ampitude / 4;
	buffer[D][y] = center[y] - ampitude / 2;
	
	buffer[E][x] = center[x] + ampitude / 4;
	buffer[E][y] = center[y] - ampitude / 2;
	
	buffer[F][x] = center[x] + ampitude / 2;
	buffer[F][y] = center[y] - ampitude / 4;
	
	buffer[G][x] = center[x] + ampitude / 2;
	buffer[G][y] = center[y] + ampitude / 4;
	
	buffer[H][x] = center[x] + ampitude / 4;
	buffer[H][y] = center[y] + ampitude / 2;
}

stock void Geo_NewTetrahedron(float center[3], float ampitude, float buffer[4][3])
{
	float lato = SquareRoot(6.0) / 4 * ampitude;
	buffer[A][x] = center[x] - lato / 2;
	buffer[A][y] = center[y] - ampitude / 2;
	buffer[A][z] = center[z] - ampitude / 2;
	
	buffer[B][x] = center[x] + lato / 2;
	buffer[B][y] = center[y] - ampitude / 2;
	buffer[B][z] = center[z] - ampitude / 2;
	
	buffer[C][x] = center[x];
	buffer[C][y] = center[y] + ampitude / 2;
	buffer[C][z] = center[z] - ampitude / 2;
	
	buffer[D][x] = center[x];
	buffer[D][y] = center[y];
	buffer[D][z] = center[z] + ampitude / 2;
}

stock void Geo_NewCube(float center[3], float ampitude, float buffer[8][3])
{
	buffer[A][x] = center[x] - ampitude / 2;
	buffer[A][y] = center[y] - ampitude / 2;
	buffer[A][z] = center[z] - ampitude / 2;
	
	buffer[B][x] = center[x] + ampitude / 2;
	buffer[B][y] = center[y] - ampitude / 2;
	buffer[B][z] = center[z] - ampitude / 2;
	
	buffer[C][x] = center[x] + ampitude / 2;
	buffer[C][y] = center[y] + ampitude / 2;
	buffer[C][z] = center[z] - ampitude / 2;
	
	buffer[D][x] = center[x] - ampitude / 2;
	buffer[D][y] = center[y] + ampitude / 2;
	buffer[D][z] = center[z] - ampitude / 2;
	
	
	buffer[E][x] = center[x] - ampitude / 2;
	buffer[E][y] = center[y] - ampitude / 2;
	buffer[E][z] = center[z] + ampitude / 2;
	
	buffer[F][x] = center[x] + ampitude / 2;
	buffer[F][y] = center[y] - ampitude / 2;
	buffer[F][z] = center[z] + ampitude / 2;
	
	buffer[G][x] = center[x] + ampitude / 2;
	buffer[G][y] = center[y] + ampitude / 2;
	buffer[G][z] = center[z] + ampitude / 2;
	
	buffer[H][x] = center[x] - ampitude / 2;
	buffer[H][y] = center[y] + ampitude / 2;
	buffer[H][z] = center[z] + ampitude / 2;	
}

stock void Geo_NewOctahedron(float center[3], float ampitude, float buffer[6][3])
{
	buffer[A][z] = center[z];
	buffer[B][z] = center[z];
	buffer[C][z] = center[z];
	buffer[D][z] = center[z];
	
	buffer[A][x] = center[x] - ampitude / 2;
	buffer[A][y] = center[y] + ampitude / 2;
	
	buffer[B][x] = center[x] - ampitude / 2;
	buffer[B][y] = center[y] - ampitude / 2;
	
	buffer[C][x] = center[x] + ampitude / 2;
	buffer[C][y] = center[y] - ampitude / 2;
	
	buffer[D][x] = center[x] + ampitude / 2;
	buffer[D][y] = center[y] + ampitude / 2;
	
	buffer[E][x] = center[x];
	buffer[E][y] = center[y];
	buffer[E][z] = center[z] + ampitude / 2;
	
	buffer[F][x] = center[x];
	buffer[F][y] = center[y];
	buffer[F][z] = center[z] - ampitude / 2;
}

stock void Geo_NewIcosahedron(float center[3], float ampitude, float buffer[12][3])
{
	float h = ampitude / 4;
	
	buffer[A][x] = center[x] - ampitude / 2;
	buffer[A][y] = center[y] - h;
	buffer[A][z] = center[z];
	
	buffer[B][x] = center[x] + ampitude / 2;
	buffer[B][y] = center[y] - h;
	buffer[B][z] = center[z];
	
	buffer[C][x] = center[x] + ampitude / 2;
	buffer[C][y] = center[y] + h;
	buffer[C][z] = center[z];
	
	buffer[D][x] = center[x] - ampitude / 2;
	buffer[D][y] = center[y] + h;
	buffer[D][z] = center[z];
	
	
	buffer[E][x] = center[x];
	buffer[E][y] = center[y] + ampitude / 2;
	buffer[E][z] = center[z] - h;
	
	buffer[F][x] = center[x];
	buffer[F][y] = center[y] - ampitude / 2;
	buffer[F][z] = center[z] - h;
	
	buffer[G][x] = center[x];
	buffer[G][y] = center[y] - ampitude / 2;
	buffer[G][z] = center[z] + h;
	
	buffer[H][x] = center[x];
	buffer[H][y] = center[y] + ampitude / 2;
	buffer[H][z] = center[z] + h;
	
	buffer[I][x] = center[x] - h;
	buffer[I][y] = center[y];
	buffer[I][z] = center[z] - ampitude / 2;
	
	buffer[L][x] = center[x] + h;
	buffer[L][y] = center[y];
	buffer[L][z] = center[z] - ampitude / 2;
	
	buffer[M][x] = center[x] + h;
	buffer[M][y] = center[y];
	buffer[M][z] = center[z] + ampitude / 2;
	
	buffer[N][x] = center[x] - h;
	buffer[N][y] = center[y];
	buffer[N][z] = center[z] + ampitude / 2;
}