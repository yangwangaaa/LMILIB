function out = checkHinfD(sys,param)
% function out = checkHinf(sys,param)
%
% Check the Hinf norm for worst case of (A,B,C,D) polytopic discrete system.
%
% input:  sys=makePolyDABCD(n,m,p,N,d,param) -> state-space polytopic discrete system 
%         param.dt -> (optional) used for ajust the grid (default dt=0.01)
%         param.n  -> (optional) used for ajust the number of
%         random points in the polytope
%        
% output: out.N             -> number of vertices
%         out.dim           -> dimension of the system
%         out.clock         -> times took for create the polytope
%         out.sigma           -> singular value of the convex combination
%         out.sigmaV          -> singular value of the vertices
%	      out.alpha         -> values of simplex 
%	      out.maxSigma        -> gretest singular value in the polytope
%         out.alphaMaxSigma  -> simplex point of the greatest sigma
%
% E.g.
% sys=makePolyDABCD(3,2,3,-1);
% Hinf=checkHinf(sys)
%
%
% Date: 23/09/2017
% Author: Marcos Rogério Fernandes
% Email: eng.marofe@hotmail.com
%% takes the parameters
out.N=sys.N;
% take vertices eig values
for i=1:out.N
    sys0 = ss(sys.A{i},sys.B{i},sys.C{i},sys.D{i},-1);
    %out.sigmaV(i)=max(max(sigma(sys0),[],2));
    out.sigmaV(i)=norm(sys0,inf);
end
out.dim=sys.dim;
out.dt=0.01; %default grid
out.n=1000; %default number of randomness point in polytope
out.subpoly=1; %default take subpolytopes for N>3
out.links=1; %default take points on the links between vertices
takeToc=1;
if nargin == 2
    if isfield(param,'dt')
        out.dt=param.dt;
    end
    if isfield(param,'n')
        out.n=param.n;
    end
    if isfield(param,'subpoly')
        out.subpoly=param.subpoly;
    end
    if isfield(param,'links')
        out.links=param.links;
    end
    if isfield(param,'toc')
        takeToc=param.toc;
    end
end
if takeToc==1
    tic
end
a=0:out.dt:1;
n=length(a);
%% check Hinf Norm for polytope with N vertices
if out.N==1
    out.alpha=1;
    sys0=ss(sys.A{1},sys.B{1},sys.C{1},sys.D{1},-1);
    %out.sigma=max(max(sigma(sys0),[],2));
    out.sigma=norm(sys0,inf);
elseif out.N==2
    for i=1:n
        A=a(i)*sys.A{1}+(1-a(i))*sys.A{2};
        B=a(i)*sys.B{1}+(1-a(i))*sys.B{2};
        C=a(i)*sys.C{1}+(1-a(i))*sys.C{2};
        D=a(i)*sys.D{1}+(1-a(i))*sys.D{2};
        sys0=ss(A,B,C,D,-1);
        %out.sigma(i)=max(max(sigma(sys0),[],2));
        out.sigma(i)=norm(sys0,inf);
        out.alpha(i,1)=a(i);
        out.alpha(i,2)=1-a(i);
    end
elseif out.N>2
    k=1;
    %% polytope greater than 2
    if out.links==1
    L=combnk(1:out.N,2);
    for j=1:size(L,1)
        for i=1:n
            A=a(i)*sys.A{L(j,1)}+(1-a(i))*sys.A{L(j,2)};
            B=a(i)*sys.B{L(j,1)}+(1-a(i))*sys.B{L(j,2)};
            C=a(i)*sys.C{L(j,1)}+(1-a(i))*sys.C{L(j,2)};
            D=a(i)*sys.D{L(j,1)}+(1-a(i))*sys.D{L(j,2)};
            sys0=ss(A,B,C,D,-1);
            %out.sigma(k)=max(max(sigma(sys0),[],2));
            out.sigma(k)=norm(sys0,inf);
            out.alpha(k,L(j,1))=a(i);
            out.alpha(k,L(j,2))=1-a(i);
            k=k+1;
        end
    end
    end
    %% points equaly likely inside the polytope
    for n=1:out.n
    %generate alpha vector: alpha=(alpha1,alpha2,...alphaN)
    out.alpha(k,1)=1-rand^(1/(out.N-1));
    for j=2:out.N-1
        out.alpha(k,j)=(1-sum(out.alpha(k,1:j-1)))*(1-rand^(1/(out.N-j)));
    end
    out.alpha(k,out.N)=1-sum(out.alpha(k,1:out.N-1));
    %make convex combination using alpha
    A=zeros(out.dim,out.dim);
    B=zeros(sys.dim,sys.input);
    C=zeros(sys.output,sys.dim);
    D=zeros(sys.output,sys.input);
    for i=1:out.N
        A=A+out.alpha(k,i)*sys.A{i};
        B=B+out.alpha(k,i)*sys.B{i};
        C=C+out.alpha(k,1)*sys.C{i};
        D=D+out.alpha(k,1)*sys.D{i};
    end
    sys0=ss(A,B,C,D,-1);
    %out.sigma(k)=max(max(sigma(sys0),[],2));
    out.sigma(k)=norm(sys0,inf);
    k=k+1;
    end
    %% take subpolytopes
    if (out.N > 3) && (out.subpoly==1)
        L=combnk(1:out.N,3);
        param2.links=0;
        param2.n=150;
        param2.toc=0;
        clear sys0
        for i=1:size(L,1)
            sys0.A={sys.A{L(i,1)},sys.A{L(i,2)},sys.A{L(i,3)}};
            sys0.B={sys.B{L(i,1)},sys.B{L(i,2)},sys.B{L(i,3)}};
            sys0.C={sys.C{L(i,1)},sys.C{L(i,2)},sys.C{L(i,3)}};
            sys0.D={sys.D{L(i,1)},sys.D{L(i,2)},sys.D{L(i,3)}};
            sys0.dim=sys.dim;
            sys0.input=sys.input;
            sys0.output=sys.output;
            sys0.N=3;
            sys0.feedforward=sys.feedforward;
            subHinf = checkHinfD(sys0,param2);
            out.sigma = [out.sigma subHinf.sigma];
            alpha = zeros(size(subHinf.alpha,1),out.N);
            alpha(:,L(i,1))=subHinf.alpha(:,1);
            alpha(:,L(i,2))=subHinf.alpha(:,2);
            alpha(:,L(i,3))=subHinf.alpha(:,3);
            out.alpha = [out.alpha; alpha];
        end
    end
end
[out.maxSigma c]=max(out.sigma);
out.alphaMaxSigma=out.alpha(c,:);
if takeToc==1
    out.clock=toc;
else
    out.clock=-1;
end
end